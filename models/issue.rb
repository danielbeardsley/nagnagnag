class Issue
   def initialize(repo, issue)
      @repo = repo
      @issue = issue
   end

   def last_comment_was_by(github_user)
      Log.debug "Checking author of last comment on issue ##{@issue.number}"
      comment = last_comment
      Log.debug "Author: #{comment && comment.user.login || '[unknown]'}"
      comment && comment.user.login == github_user
   end

   def is_old
      @issue.updated_at < (Time.now - 30 * 24 * 60 * 60)
   end

   def number
      @issue && @issue.number
   end

   ##
   # Returns array of Issue objects for all issues that haven't been updated
   # in @options[:no_activity_days]
   ##
   def self.old_issues(repo)
      Log.info "Loading issues and selecting only the stale"
      issues = Github.api.issues(repo, {
         # all = don't limit to issues assigned to me
         # :filter     => :all,
         :state      => :open,
         :sort       => :updated,
         :direction  => :asc,
         :asignee    => "*"
      })

      batch = issues
      all = []
      while true
         Log.info "Loaded batch of #{batch.length} issues"
         batch.each do |issue_data|
            issue = Issue.new(repo, issue_data)
            if issue.is_old
               if !issue_data[:pull_request]
                  all << issue
                  Log.debug "Issue ##{issue.number} is stale"
               end
            else
               Log.info "Found #{all.length} stable issues"
               return all
            end
         end
         if batch.length != 0
            batch = Octokit.last_response.rels[:next].get.data
         end
      end
   end

   def last_comment
      Log.info "Loading last_comment for issue ##{@issue.number}"
      comments = Nagnagnag.Github.api.issue_comments(@repo, @issue.number, {
         :sort => :created,
         :direction => :desc
      })
      comments[0] && Comment.new(comments[0])
   end

   def close
      Log.info "Closing issue ##{@issue.number}"
   end

   def comment_on_issue
      Log.info "Commenting on issue ##{@issue.number}"
   end
end
