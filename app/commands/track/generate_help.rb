class Track
  class GenerateHelp
    include Mandate

    initialize_with :track

    def call
      <<~TEXT.strip
        # Help

        #{Markdown::Render.(track.git.help, :text)}

        #{I18n.t('exercises.documents.help_check_pages')}

        #{I18n.t('exercises.documents.help_pages', track_title: track.title, track_slug: track.slug).strip}
      TEXT
    end
  end
end
