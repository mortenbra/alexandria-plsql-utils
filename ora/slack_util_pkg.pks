create or replace package slack_util_pkg
as
 
  /*
 
  Purpose:      Package handles Slack API
 
  Remarks:      see https://api.slack.com/

  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     17.02.2018  Created
 
  */

  -- set API base URL
  procedure set_api_base_url (p_url in varchar2);

  -- set SSL wallet properties
  procedure set_wallet (p_wallet_path in varchar2,
                        p_wallet_password in varchar2);

  -- set webhook host
  procedure set_webhook_host (p_host in varchar2);

  -- set webhook path
  procedure set_webhook_path (p_path in varchar2);

  -- send message
  procedure send_message (p_text in varchar2);
 

end slack_util_pkg;
/

