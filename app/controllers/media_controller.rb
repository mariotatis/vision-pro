class MediaController < ApplicationController
  before_action :set_medium, only: [:show, :destroy]

  def index
    @media = Medium.all.order(created_at: :desc)
  end

  def show
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

  def set_medium
    @medium = Medium.find(params[:id])
  end

  def medium_params
    params.require(:medium).permit(:name, :file_type, :aws_url)
  end
end
