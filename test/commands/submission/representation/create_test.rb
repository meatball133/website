require 'test_helper'

class Submission::Representation::CreateTest < ActiveSupport::TestCase
  test "creates submission representation record" do
    submission = create :submission
    ops_status = 200
    ast = "here(lives(an(ast)))"
    ast_digest = Submission::Representation.digest_ast(ast)

    job = create_representer_job!(submission, execution_status: ops_status, ast:)
    representation = Submission::Representation::Create.(submission, job, ast_digest)

    assert_equal job.id, representation.tooling_job_id
    assert_equal ops_status, representation.ops_status
    assert_equal ast_digest, representation.ast_digest
  end

  test "updates mentor of submission representation" do
    mentor = create :user
    iteration = create :iteration
    submission = iteration.submission
    discussion = create :mentor_discussion, mentor: mentor, solution: iteration.solution
    create :mentor_discussion_post, discussion: discussion, iteration: iteration, author: mentor

    job = create_representer_job!(submission, execution_status: 200, ast: "here(lives(an(ast)))")
    representation = Submission::Representation::Create.(submission, job, "the_digest")
    perform_enqueued_jobs

    assert_equal mentor, representation.reload.mentored_by
  end
end
