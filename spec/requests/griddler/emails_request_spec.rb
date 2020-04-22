require 'spec_helper'

RSpec.describe 'Receiving Email', type: :request do
  before(:each) do
    fake_adapter = double(normalize_params: normalized_params)
    Griddler.adapter_registry.register(:one_that_works, fake_adapter)
    Griddler.configuration.email_service = :one_that_works
  end

  let(:path) { '/v1/email_processor' }

  describe 'POST create' do
    it 'is successful' do
      post path, params: email_params

      expect(response).to be_successful
    end

    context 'with another API version' do
      let(:path) { '/v2/email_processor' }

      it 'is also successful' do
        post path, params: email_params

        expect(response).to be_successful
      end
    end

    it 'creates a new Griddler::Email with the given params' do
      email = double
      expect(Griddler::Email).to receive(:new).
        with(hash_including(to: ['tb@example.com'])).
        and_return(email)

      post path, params: { to: 'tb@example.com' }
    end

    it 'calls process on the custom processor class' do
      my_handler = double(process: nil)
      expect(my_handler).to receive(:new).and_return(my_handler)
      allow(Griddler.configuration).to receive_messages(processor_class: my_handler)

      post path, params: email_params
    end

    it 'calls the custom processor method on the processor class' do
      allow(Griddler.configuration).to receive_messages(processor_method: :perform)
      fake_processor = double(perform: nil)

      expect(EmailProcessor).to receive(:new).and_return(fake_processor)
      expect(fake_processor).to receive(:perform)

      post path, params: email_params
    end
  end

  def email_params
    {
      headers: 'Received: by 127.0.0.1 with SMTP...',
      to: 'thoughtbot <tb@example.com>',
      cc: 'CC <cc@example.com>',
      from: 'John Doe <someone@example.com>',
      subject: 'hello there',
      text: 'this is an email message',
      html: '<p>this is an email message</p>',
      charsets: '{"to":"UTF-8","html":"ISO-8859-1","subject":"UTF-8","from":"UTF-8","text":"ISO-8859-1"}',
      SPF: "pass"
    }
  end

  def normalized_params
    {
      to: ['tb@example.com'],
      from: 'tb@example.com',
      cc: [],
    }
  end
end
