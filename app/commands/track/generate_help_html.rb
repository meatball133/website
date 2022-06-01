class Track
  class GenerateHelpHTML
    include Mandate

    initialize_with :track

    def call = Markdown::Parse.(help_text)

    private
    def help_text
      <<~TEXT.strip
        # Help

        #{general_help_text}

        #{track_help_text}
      TEXT
    end

    def general_help_text
      I18n.t("exercises.documents.help", track_title: track.title, track_slug: track.slug).strip
    end

    def track_help_text = Markdown::Render.(track.git.help, :text)
  end
end
