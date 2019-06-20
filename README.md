# Redmine Slack Notifier

This plugin notifies Slack about ticket creation and updates.

## Instalation

```
git clone https://github.com/neptaco/redmine_slack_notififer.git redmine_slack_notifier
```

```
bundle install
bundle exec rake redmine:plugins:migrate
```

## Setup

### Create Slack Bot Api Token

Create Apps and Get Bot token
https://api.slack.com/apps

### Setup Slack Api Token

1. Administration -> Plugins -> Redmine Slack Notifier plugin (Configure)
2. Input `Slack Api Token`

### Personal settings

http[s]://{host}/my/account ->  Slack notifier enabled

Notification policy reference Email notifications settings 

### Shared channel settings

Please set the channel name to post in any of the following.

- Project Settings -> share_channel
    - Can be set for each project
- Administration -> Plugins -> Redmine Slack Notifier plugin (Configure)
    - Projects with empty project individual settings use this.
