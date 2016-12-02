create or replace package paypal_util_pkg
as
 
  /*
 
  Purpose:      Package handles PayPal REST API
 
  Remarks:      see https://developer.paypal.com/webapps/developer/docs/api/
                see https://developer.paypal.com/webapps/developer/docs/integration/direct/make-your-first-call/
                see https://devtools-paypal.com/hateoas/index.html
                see https://www.youtube.com/watch?v=EdkQahMUvAY
 
  Who     Date        Description
  ------  ----------  --------------------------------
  MBR     23.08.2014  Created
  MBR     06.03.2016  Procedure to set API base URL
 
  */

  -- access token
  type t_access_token is record (
    access_token      varchar2(4000),
    token_type        varchar2(255),
    duration_seconds  number,
    created_date      date,
    expires_date      date
  );

  -- payment
  type t_payment is record (
    payment_id        varchar2(255),
    intent            varchar2(255),
    state             varchar2(255),
    approval_url      varchar2(4000)
  );

  -- payment experience flow config
  type t_pe_flow_config is record (
    landing_page_type        varchar2(255)
  );

  -- payment experience input fields
  type t_pe_input_fields is record (
    allow_note        boolean,
    no_shipping       pls_integer,
    address_override  pls_integer
  );

  -- payment experience presentation
  type t_pe_presentation is record (
    brand_name        varchar2(255),
    logo_image        varchar2(255),
    locale_code       varchar2(255)
  );

  -- payment web experience profile
  type t_payment_experience is record (
    payment_experience_id    varchar2(255),
    payment_experience_name  varchar2(255),
    flow_config              t_pe_flow_config,
    input_fields             t_pe_input_fields,
    presentation             t_pe_presentation
  );

  -- payment states
  g_state_created                constant varchar2(255) := 'created';
  g_state_approved               constant varchar2(255) := 'approved';
  g_state_failed                 constant varchar2(255) := 'failed';
  g_state_canceled               constant varchar2(255) := 'canceled';
  g_state_expired                constant varchar2(255) := 'expired';
 
  -- set API base URL
  procedure set_api_base_url (p_sandbox_url in varchar2,
                              p_live_url in varchar2);

  -- switch to sandbox (test) environment
  procedure switch_to_sandbox;
 
  -- set SSL wallet properties
  procedure set_wallet (p_wallet_path in varchar2,
                        p_wallet_password in varchar2);
 
  -- get access token for other API requests
  function get_access_token (p_client_id in varchar2,
                             p_secret in varchar2) return t_access_token;
 
  -- create payment
  function create_payment (p_access_token in t_access_token,
                           p_amount in number,
                           p_currency in varchar2,
                           p_description in varchar2,
                           p_return_url in varchar2,
                           p_cancel_url in varchar2,
                           p_payment_experience_id in varchar2 := null) return t_payment;
 
  -- execute payment
  function execute_payment (p_access_token in t_access_token,
                            p_payment_id in varchar2,
                            p_payer_id in varchar2) return t_payment;
 
  -- get payment
  function get_payment (p_access_token in t_access_token,
                        p_payment_id in varchar2) return t_payment;

  -- create payment experience
  function create_payment_experience (p_access_token in t_access_token,
                                      p_payment_experience in t_payment_experience) return varchar2;
 
  -- delete payment experience
  procedure delete_payment_experience (p_access_token in t_access_token,
                                       p_payment_experience_id in varchar2);

end paypal_util_pkg;
/

