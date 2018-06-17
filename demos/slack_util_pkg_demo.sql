
-- send message to Slack using webhook
-- see https://api.slack.com/incoming-webhooks

begin 
  -- create your own incoming webhook in Slack, then paste the path to the webhook here
  slack_util_pkg.set_webhook_path ('/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX');
  -- send a basic message
  slack_util_pkg.send_message ('Hello Slack World!');
  -- send a formatted message
  slack_util_pkg.send_message ('Hello *Slack* World! This is a _message from PL/SQL_ sent using the <https://github.com/mortenbra|Alexandria PL/SQL Utility Library>.');
end;
/



