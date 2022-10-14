require 'test_helper'

class ExerciseTest < ActiveSupport::TestCase
  test "to_slug" do
    exercise = create :concept_exercise
    assert_equal exercise.slug, exercise.to_param
  end

  test "prerequisites works correctly" do
    exercise = create :concept_exercise

    concept = create :concept
    create :concept

    exercise.prerequisites << concept

    assert_equal [concept], exercise.reload.prerequisites
  end

  test "scope :without_prerequisites" do
    exercise_1 = create :concept_exercise
    exercise_2 = create :concept_exercise

    assert_equal [exercise_1, exercise_2], Exercise.without_prerequisites

    create :exercise_prerequisite, exercise: exercise_1
    assert_equal [exercise_2], Exercise.without_prerequisites
  end

  test "scope :published" do
    create :concept_exercise, status: :wip
    beta = create :concept_exercise, status: :beta
    active = create :concept_exercise, status: :active
    create :concept_exercise, status: :deprecated

    assert_equal [beta, active], Exercise.published
  end

  test "scope :sorted" do
    exercise_1 = create :practice_exercise, position: 0
    exercise_2 = create :concept_exercise, position: 1
    exercise_3 = create :concept_exercise, position: 2
    exercise_4 = create :practice_exercise, position: 3

    assert_equal [exercise_1, exercise_2, exercise_3, exercise_4], Exercise.sorted
  end

  test "scope :started" do
    track = create :track
    wip = create :concept_exercise, status: :wip, track: track
    beta = create :practice_exercise, status: :beta, track: track
    active = create :concept_exercise, status: :active, track: track
    deprecated = create :practice_exercise, status: :deprecated, track: track

    user_1 = create :user
    user_2 = create :user
    user_track_1 = create :user_track, track: track, user: user_1
    user_track_2 = create :user_track, track: track, user: user_2

    assert_empty Exercise.started(user_track_1)
    assert_empty Exercise.started(user_track_2)

    create :concept_solution, user: user_1, exercise: wip
    assert_equal [wip], Exercise.started(user_track_1).order(:id)
    assert_empty Exercise.started(user_track_2).order(:id)

    create :practice_solution, user: user_1, exercise: beta
    assert_equal [wip, beta], Exercise.started(user_track_1).order(:id)
    assert_empty Exercise.started(user_track_2).order(:id)

    create :concept_solution, user: user_2, exercise: active
    assert_equal [wip, beta], Exercise.started(user_track_1).order(:id)
    assert_equal [active], Exercise.started(user_track_2).order(:id)

    create :practice_solution, user: user_1, exercise: deprecated
    assert_equal [wip, beta, deprecated], Exercise.started(user_track_1).order(:id)
    assert_equal [active], Exercise.started(user_track_2).order(:id)
  end

  test "scope :available" do
    track = create :track
    wip = create :concept_exercise, status: :wip, track: track
    beta = create :practice_exercise, status: :beta, track: track
    active = create :concept_exercise, status: :active, track: track
    deprecated = create :practice_exercise, status: :deprecated, track: track

    user_1 = create :user
    user_2 = create :user
    user_track_1 = create :user_track, track: track, user: user_1
    user_track_2 = create :user_track, track: track, user: user_2

    assert_equal [beta, active], Exercise.available(user_track_1).order(:id)
    assert_equal [beta, active], Exercise.available(user_track_2).order(:id)

    create :practice_solution, user: user_1, exercise: deprecated
    assert_equal [beta, active, deprecated], Exercise.available(user_track_1).order(:id)
    assert_equal [beta, active], Exercise.available(user_track_2).order(:id)

    create :practice_solution, user: user_2, exercise: wip
    assert_equal [beta, active, deprecated], Exercise.available(user_track_1).order(:id)
    assert_equal [wip, beta, active], Exercise.available(user_track_2).order(:id)
  end

  test "prerequisite_exercises" do
    strings = create :concept
    bools = create :concept
    conditionals = create :concept

    exercise = create :practice_exercise
    exercise.prerequisites << strings
    exercise.prerequisites << bools

    pre_ex_1 = create(:concept_exercise)
    pre_ex_1.taught_concepts << strings

    pre_ex_2 = create(:concept_exercise)
    pre_ex_2.taught_concepts << bools

    pre_ex_3 = create(:concept_exercise)
    pre_ex_3.taught_concepts << conditionals

    assert_equal [pre_ex_1, pre_ex_2], exercise.prerequisite_exercises
  end

  test "difficulty_category" do
    {
      easy: [1, 2, 3],
      medium: [4, 5, 6, 7],
      hard: [8, 9, 10]
    }.each do |category, values|
      values.each do |val|
        assert_equal category, create(:practice_exercise, difficulty: val).difficulty_category
      end
    end
  end

  test "icon_url" do
    exercise = create :practice_exercise, slug: 'bob', icon_name: 'bobby'
    assert_equal "https://exercism-v3-icons.s3.eu-west-2.amazonaws.com/exercises/bobby.svg", exercise.icon_url
  end

  test "git_important_files_sha is generated" do
    exercise = create :practice_exercise, slug: 'bob', git_important_files_hash: nil
    assert_equal 'b72b0958a135cddd775bf116c128e6e859bf11e4', exercise.git_important_files_hash
  end

  test "git_important_files_sha is re-generated when git_sha changes" do
    exercise = create :practice_exercise, slug: 'allergies', git_sha: '6f169b92d8500d9ec5f6e69d6927bf732ab5274a',
      git_important_files_hash: nil
    assert_equal 'b428b458004f45ba78c4b9f0c386f9987a17452e', exercise.git_important_files_hash

    exercise.update!(git_sha: '9aba0406b02303efe9542e48ab6f4eee0b00e6f1')
    assert_equal '8fadc126ecd6ef6b7075a36517292beec521e39a', exercise.git_important_files_hash
  end

  test "has_test_runner?" do
    track = create :track, has_test_runner: true
    exercise = create :practice_exercise, track: track, has_test_runner: true

    assert exercise.has_test_runner?

    exercise.update(has_test_runner: false)
    refute exercise.has_test_runner?

    exercise.update(has_test_runner: true)
    track.update(has_test_runner: false)
    refute exercise.has_test_runner?
  end

  test "enqueues job to mark solutions as out-of-date in index when git_important_files_hash changes" do
    exercise = create :practice_exercise

    assert_enqueued_with(job: MandateJob, args: [Exercise::MarkSolutionsAsOutOfDateInIndex.name, exercise]) do
      exercise.update!(git_important_files_hash: 'new-hash')
    end
  end

  test "does not enqueue job to mark solutions as out-of-date in index when git_important_files_hash does not change" do
    exercise = create :practice_exercise

    assert_no_enqueued_jobs only: MandateJob do
      exercise.update!(position: 2)
    end
  end

  test "enqueues job to run head test runs when git_important_files_hash changes" do
    exercise = create :practice_exercise

    assert_enqueued_with(job: MandateJob, args: [Exercise::QueueSolutionHeadTestRuns.name, exercise]) do
      exercise.update!(git_important_files_hash: 'new-hash')
    end
  end

  test "does not enqueue job to run head test runs when git_important_files_hash does not change" do
    exercise = create :practice_exercise

    assert_no_enqueued_jobs only: MandateJob do
      exercise.update!(position: 2)
    end
  end

  test "updates track num_exercises when created" do
    track = create :track
    track.expects(:recache_num_exercises!).once
    create :practice_exercise, track:
  end

  test "updates track num_exercises when deleted" do
    track = create :track
    exercise = create :practice_exercise, track: track

    track.expects(:recache_num_exercises!).once
    exercise.destroy
  end

  test "updates track num_exercises when status column changed" do
    track = create :track
    exercise = create :practice_exercise, track: track

    track.expects(:recache_num_exercises!).once
    exercise.update(status: :beta)
  end

  test "doesn't update track num_exercises when other column changed" do
    track = create :track
    exercise = create :practice_exercise, track: track

    track.expects(:recache_num_exercises!).never
    exercise.update(title: 'something')
  end
end
