class Solution
  class GenerateHelpFile
    include Mandate

    initialize_with :solution

    def call
      <<~TEXT.strip
        # Help

        #{tests}

        #{submitting}

        #{help}
      TEXT
    end

    private
    def tests
      <<~TEXT.strip
        ## #{I18n.t('exercises.documents.tests_header')}

        #{Markdown::Render.(track.git.tests, :text).strip}
      TEXT
    end

    def submitting
      <<~TEXT.strip
        ## #{I18n.t('exercises.documents.submitting_solution_header')}

        #{I18n.t('exercises.documents.submitting_solution', solution_file_paths: exercise.git.solution_filepaths.join(' '))}
      TEXT
    end

    def help
      <<~TEXT.strip
        ## #{I18n.t('exercises.documents.help_header')}

        #{I18n.t('exercises.documents.help_intro')}

        #{I18n.t('exercises.documents.help_pages', track_title: track.title, track_slug: track.slug)}

        #{I18n.t('exercises.documents.help_submit_incomplete')}

        #{Markdown::Render.(track.git.help, :text).strip}
      TEXT
    end

    def track = solution.track
    def exercise = solution.exercise
  end
end
