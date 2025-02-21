require "test_helper"

class Mentoring::AutomationControllerTest < ActionDispatch::IntegrationTest
  %i[admin staff supermentor].each do |role|
    test "index: renders correctly for #{role}" do
      user = create :user, role
      sign_in!(user)

      get mentoring_automation_index_path

      assert_template "mentoring/automation/index"
    end
  end

  test "index: redirects non supermentors" do
    user = create :user
    sign_in!(user)

    get mentoring_automation_index_path
    assert_redirected_to mentoring_path
  end

  test "with_feedback: renders correctly for supermentor" do
    user = create :user, :supermentor
    sign_in!(user)

    get with_feedback_mentoring_automation_index_path

    assert_template "mentoring/automation/with_feedback"
  end

  test "with_feedback: redirects non supermentors" do
    user = create :user
    sign_in!(user)

    get with_feedback_mentoring_automation_index_path
    assert_redirected_to mentoring_path
  end

  test "edit: renders correct for supermentors" do
    user = create :user, :supermentor
    sign_in!(user)

    representation = create :exercise_representation
    get edit_mentoring_automation_path(representation)

    assert_template "mentoring/automation/edit"
  end

  test "edit: raises when representation could not be found" do
    user = create :user, :supermentor
    sign_in!(user)

    assert_raises ActiveRecord::RecordNotFound do
      get edit_mentoring_automation_path('XXX')
    end
  end

  test "edit: redirects non supermentors" do
    user = create :user
    sign_in!(user)

    representation = create :exercise_representation

    get edit_mentoring_automation_path(representation)
    assert_redirected_to mentoring_path
  end

  test "tooltip_locked: renders correctly for supermentor" do
    user = create :user, :supermentor
    sign_in!(user)

    get tooltip_locked_mentoring_automation_index_path

    assert_template "mentoring/automation/tooltip_locked"
  end

  test "tooltip_locked: renders correctly for non supermentors" do
    user = create :user
    sign_in!(user)

    get tooltip_locked_mentoring_automation_index_path

    assert_template "mentoring/automation/tooltip_locked"
  end
end
