require 'net/http'
require 'uri'
require 'json'

class MediaController < ApplicationController
  before_action :set_medium, only: [:show, :destroy, :analyze]

  def index
    @media = Medium.all.order(created_at: :desc)
  end

  def show
  end
  
  def analyze
    if @medium.file_type.start_with?('image/')
      # Check if analysis results already exist
      if analysis_exists?(@medium)
        redirect_to medium_path(@medium), notice: 'Analysis results already exist.'
      else
        result = analyze_with_vision_api
        if result
          redirect_to medium_path(@medium), notice: 'Image analysis completed.'
        else
          redirect_to medium_path(@medium), alert: 'Image analysis failed. Please try again.'
        end
      end
    else
      redirect_to medium_path(@medium), alert: 'Only images can be analyzed.'
    end
  end

  def new
    @medium = Medium.new
  end

  def create
    @medium = Medium.new(medium_params)
    
    if params[:medium][:file].present?
      file = params[:medium][:file]
      s3_key = "vision/#{SecureRandom.uuid}-#{file.original_filename}"
      
      begin
        s3_client = Aws::S3::Client.new(
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: ENV['AWS_REGION']
        )
        
        s3_client.put_object(
          bucket: ENV['AWS_BUCKET'],
          key: s3_key,
          body: file.read,
          content_type: file.content_type,
          acl: 'public-read'
        )
        
        @medium.name = file.original_filename
        @medium.file_type = file.content_type
        @medium.aws_url = "https://#{ENV['AWS_BUCKET']}/#{s3_key}"
        
        if @medium.save
          # Only analyze images
          if @medium.file_type.start_with?('image/')
            # Call Vision API asynchronously
            AnalyzeImageJob.perform_later(@medium.id)
          end
          redirect_to medium_path(@medium), notice: 'File was successfully uploaded.'
        else
          render :new, status: :unprocessable_entity
        end
      rescue => e
        @medium.errors.add(:base, "Error uploading to S3: #{e.message}")
        render :new, status: :unprocessable_entity
      end
    else
      @medium.errors.add(:file, "must be attached")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @medium.destroy
    redirect_to media_path, notice: 'Media was successfully deleted.'
  end

  private
  
  # Check if analysis results already exist
  def analysis_exists?(medium)
    # Check if any of the analysis fields have values
    return medium.description1.present? || 
           medium.description2.present? || 
           medium.description3.present? || 
           medium.description4.present? || 
           medium.description5.present? || 
           medium.bestGuessLabel.present?
  end

  def analyze_with_vision_api
    # Skip analysis if results already exist
    return true if analysis_exists?(@medium)
    
    begin
      # Log the URL being analyzed
      Rails.logger.info "Analyzing image: #{@medium.aws_url}"
      
      uri = URI.parse("https://vision.googleapis.com/v1/images:annotate")
      uri.query = "key=#{ENV['AWS_ACCESS_TOKEN']}"
      
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      
      # Create the request body
      request_body = {
        "requests": [
          {
            "image": {
              "source": {
                "imageUri": @medium.aws_url
              }
            },
            "features": [
              {
                "maxResults": 5,
                "type": "WEB_DETECTION"
              },
              {
                "maxResults": 5,
                "type": "LABEL_DETECTION"
              }
            ]
          }
        ]
      }
      
      # Log the request body
      Rails.logger.info "Request body: #{request_body.to_json}"
      request.body = request_body.to_json
      
      req_options = {
        use_ssl: uri.scheme == "https",
        open_timeout: 30,  # Set timeouts to avoid hanging
        read_timeout: 30
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      
      # Log the response
      Rails.logger.info "Response code: #{response.code}"
      Rails.logger.info "Response body: #{response.body[0..500]}" # Log first 500 chars to avoid huge logs
      
      if response.code == "200"
        result = JSON.parse(response.body)
        
        if result["responses"] && result["responses"][0] && result["responses"][0]["webDetection"]
          web_detection = result["responses"][0]["webDetection"]
          
          # Clear previous values
          (1..5).each do |i|
            @medium.send("score#{i}=", nil)
            @medium.send("description#{i}=", nil)
          end
          @medium.bestGuessLabel = nil
          
          # Store web entities
          if web_detection["webEntities"]
            web_detection["webEntities"].each_with_index do |entity, index|
              break if index >= 5
              @medium.send("score#{index+1}=", entity["score"].to_s)
              @medium.send("description#{index+1}=", entity["description"])
            end
          end
          
          # Store best guess label
          if web_detection["bestGuessLabels"] && web_detection["bestGuessLabels"][0]
            @medium.bestGuessLabel = web_detection["bestGuessLabels"][0]["label"]
          end
          
          @medium.save
          return true
        end
      end
      return false
    rescue => e
      Rails.logger.error "Error analyzing image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return false
    end
  end

  def set_medium
    @medium = Medium.find(params[:id])
  end

  def medium_params
    params.require(:medium).permit(:name, :file_type, :aws_url)
  end
end
