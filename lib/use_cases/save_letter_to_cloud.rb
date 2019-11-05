module UseCases
  class SaveLetterToCloud
    def initialize(cloud_gateway)
      @cloud_gateway = cloud_gateway
    end

    def execute(filename:, bucket_name:, pdf:)
      raise ArgumentError unless filename.present?
      raise ArgumentError unless bucket_name.present?
      raise ArgumentError unless pdf.present?

      @cloud_gateway.upload(
        binary_letter_content: pdf,
        bucket_name: bucket_name,
        filename: filename
      )
    end
  end
end
