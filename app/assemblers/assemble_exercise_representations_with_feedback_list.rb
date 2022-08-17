class AssembleExerciseRepresentationsWithFeedbackList
  include Mandate

  initialize_with :user, :params

  def self.keys = %i[page order criteria track_slug]

  def call
    SerializePaginatedCollection.(
      representations,
      serializer: SerializeExerciseRepresentations,
      meta: {
        unscoped_total: Exercise::Representation.with_feedback.count
      }
    )
  end

  private
  memoize
  def representations
    Exercise::Representation::Search.(
      user:,
      track:,
      status: :with_feedback,
      page: params[:page],
      order: params[:order],
      criteria: params[:criteria]
    )
  end

  def track
    return if params[:track_slug].blank?

    Track.find(params[:track_slug])
  end
end
