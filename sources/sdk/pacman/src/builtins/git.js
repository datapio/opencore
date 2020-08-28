const get_repo_info = require('git-repo-info')

module.exports = async () => {
  const path = process.cwd()
  const repo = get_repo_info(`${path}/.git`)

  return {
    requires: [],
    interface: () => ({
      commit: () => ({
        author: repo.author,
        author_date: repo.authorDate,
        committer: repo.committer,
        message: repo.commitMessage,
        date: repo.committerDate,
        sha: repo.sha,
        abbrev: repo.abbreviatedSha
      }),
      branch: () => repo.branch,
      tag: () => repo.tag,
      last_tag: () => repo.lastTag,
      commits_since_last_tags: () => repo.commitsSinceLastTag
    })
  }
}
