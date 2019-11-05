module UseCases
  class GeneratePdf
    def execute(uuid:, letter_html:)
      @pdf_generator = Hackney::PDF::Generator.new
      pdf_obj = @pdf_generator.execute(letter_html.dup)
      file_obj = pdf_obj.to_file("tmp/#{uuid}.pdf")
      File.delete("tmp/#{uuid}.pdf")
      file_obj
    end
  end
end
