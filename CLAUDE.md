# Creating a PR

You can create a PR using AGit:
```
git push origin HEAD:refs/for/main -o topic="topic_of_my_PR" -o title="Title of the PR" -o description="# The PR Description\nThis can be **any** markdown content.\n- [x] Ok"
```
Here is how the options work:

- `-o <topic|title|description>`: Options for the PR
  - `topic`: The topic of this change. It will become the name of the branch holding the changes waiting for review.  This is REQUIRED to trigger a pull request.
  - `title`: The PR title (optional but recommended), only used for topics not already having an associated PR.
  - `description`: The PR description (optional but recommended), only used for topics not already having an associated PR.
  - `force-push=true`: Specifies whether to force-update the target branch.
    - Note: omitting the value and using just `-o force-push` will also work.
