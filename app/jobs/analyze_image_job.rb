class AnalyzeImageJob < ApplicationJob
  queue_as :default

  def perform(medium_id)
    medium = Medium.find_by(id: medium_id)
    return unless medium && medium.file_type.start_with?('image/')
    
    # Skip analysis if results already exist
    return if analysis_exists?(medium)

    begin
      # Log the URL being analyzed
      Rails.logger.info "[AnalyzeImageJob] Analyzing image: #{medium.aws_url}"
      
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
                "imageUri": medium.aws_url
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
      Rails.logger.info "[AnalyzeImageJob] Request body: #{request_body.to_json}"
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
      Rails.logger.info "[AnalyzeImageJob] Response code: #{response.code}"
      Rails.logger.info "[AnalyzeImageJob] Response body: #{response.body[0..500]}" # Log first 500 chars
      
      if response.code == "200"
        result = JSON.parse(response.body)
        
        if result["responses"] && result["responses"][0] && result["responses"][0]["webDetection"]
          web_detection = result["responses"][0]["webDetection"]
          
          # Clear previous values
          (1..5).each do |i|
            medium.send("score#{i}=", nil)
            medium.send("description#{i}=", nil)
          end
          medium.bestGuessLabel = nil
          
          # Store web entities
          if web_detection["webEntities"]
            web_detection["webEntities"].each_with_index do |entity, index|
              break if index >= 5
              medium.send("score#{index+1}=", entity["score"].to_s)
              medium.send("description#{index+1}=", entity["description"])
            end
          end
          
          # Store best guess label
          if web_detection["bestGuessLabels"] && web_detection["bestGuessLabels"][0]
            medium.bestGuessLabel = web_detection["bestGuessLabels"][0]["label"]
          end
          
          medium.save
          Rails.logger.info "[AnalyzeImageJob] Successfully analyzed and saved image data"
          return true
        end
      end
      Rails.logger.warn "[AnalyzeImageJob] Failed to analyze image: Invalid response"
      return false
    rescue => e
      Rails.logger.error "[AnalyzeImageJob] Error analyzing image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return false
    end
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
end
