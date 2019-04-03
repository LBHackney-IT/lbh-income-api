class DocumentsController < ApplicationController
  LETTER_FILE_NAME = 'letter.pdf'.freeze

  def download
    response = letter_use_case_factory.download.execute(id: params.fetch(:id))

    send_file response[:filepath], type: 'application/pdf', filename: LETTER_FILE_NAME
  end
end
