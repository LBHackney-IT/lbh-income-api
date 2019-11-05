module MockAwsHelper
  def mock_aws_client
    # rubocop:disable RSpec/MessageChain
    allow_any_instance_of(Aws::S3::Encryption::Client)
      .to receive_message_chain(:put_object, :context, :http_request, :headers)
      .and_return('x-amz-date' => Time.new(2002).to_s)

    allow_any_instance_of(Aws::S3::Encryption::Client)
      .to receive_message_chain(:put_object, :context, :http_request, :endpoint)
      .and_return('blah.com')

    allow_any_instance_of(Aws::S3::Encryption::Client)
      .to receive_message_chain(:get_object, :body, :read)
      .and_return('PDF Content')
    # rubocop:enable RSpec/MessageChain
  end
end
