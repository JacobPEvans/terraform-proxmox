const LABEL_NAME = 'ai:reviewed';
const LABEL_COLOR = 'FB923C';
const LABEL_DESCRIPTION = 'AI has performed a final review on this PR';

async function addLabel(github, owner, repo, prNumber) {
  await github.rest.issues.addLabels({
    owner,
    repo,
    issue_number: prNumber,
    labels: [LABEL_NAME],
  });
}

module.exports = async ({ github, context, core }) => {
  const prNumber = parseInt(process.env.PR_NUMBER, 10);
  if (isNaN(prNumber)) {
    core.setFailed('PR_NUMBER not set');
    return;
  }
  const { owner, repo } = context.repo;

  await addLabel(github, owner, repo, prNumber);
  core.info(`Added ${LABEL_NAME} label to PR #${prNumber}`);
};
