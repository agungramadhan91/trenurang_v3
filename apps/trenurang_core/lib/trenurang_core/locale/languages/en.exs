%{
  # --- Common ---
  common_error: "Something went wrong. Please try again.",
  common_cancel: "Cancelled.",
  common_invalid_input: "Invalid input. Please try again.",
  common_not_found: "Not found.",
  common_unauthorized: "You don't have access to this feature.",
  common_yes: "Yes",
  common_no: "No",
  common_back: "« Back",
  common_save: "Save",
  common_edit: "Edit",
  common_cancel_action: "Cancel",
  common_continue: "Continue",
  common_done: "Done",
  common_confirm: "Confirm",
  common_skip: "Skip",
  common_or: "or",
  common_coming_soon: "🚧 This feature is coming soon. Stay tuned!",

  # --- Start & Welcome ---
  start_welcome_new:
    "Hello! 👋 Welcome to *Trenurang* — your market assistant for buying, selling, and connecting.\n\nWhere would you like to start?",
  start_welcome_back: "Welcome back, *%{name}*! 👋 What would you like to do today?",
  start_guest_menu: "🛍 Explore market\n📋 Register now\nℹ️ About Trenurang",
  start_btn_explore: "🛍 Explore Market",
  start_btn_register: "📋 Register",
  start_btn_about: "ℹ️ About",

  # --- Register ---
  register_start:
    "Let's get you registered!\n\n*Step 1 of 5*\nWhat's your name? (full name or nickname)",
  register_step1_name_invalid:
    "Invalid name. Use 2–30 characters, max 3 words, no common words.",
  register_step2_username:
    "*Step 2 of 5*\nChoose a unique username.\nExample: `budi_jkt` or `warung_maju`\n_(Lowercase letters, numbers, or underscores only)_",
  register_step2_username_taken: "Username *%{username}* is already taken. Please try another.",
  register_step2_username_invalid:
    "Invalid username. Use lowercase letters, numbers, or underscores (3–30 characters).",
  register_step3_email:
    "*Step 3 of 5*\nEnter your email (optional).\nUsed for billing notifications and important updates.",
  register_step3_email_invalid:
    "Invalid email format. Please try again or press Skip.",
  register_step4_location:
    "*Step 4 of 5*\nShare your location so nearby markets can find you. 📍\n\nSend via Telegram location button or type your city/district name.",
  register_step4_location_invalid:
    "Location not recognized. Try sending via Telegram's location button or type your city name.",
  register_step5_confirm:
    "*Step 5 of 5* — Review your details:\n\n👤 Name: *%{name}*\n🔖 Username: `%{username}`\n📧 Email: *%{email}*\n📍 Location: *%{location}*\n\nLooks good?",
  register_btn_save: "✅ Save & Start",
  register_btn_restart: "🔄 Start Over",
  register_btn_skip: "⏭️ Skip",
  register_success:
    "🎉 Welcome, *%{name}*!\n\nYour Trenurang account is active. You can now explore the market, create a store, or place an order.",
  register_interrupted:
    "You're in the middle of registration.\n\nWould you like to continue where you left off or start over?",
  register_btn_resume: "▶️ Resume",

  # --- Home ---
  home_buyer: "Hello, *%{name}*! 👋\nWhat are you looking for today?",
  home_seller: "Hello, *%{name}*! 🏪\nYour active store: *%{store_name}*",
  home_guest: "Hello! 👋 You're not logged in.\nWant to explore first or register?",
  home_btn_market: "🛍 Market",
  home_btn_store: "🏪 My Store",
  home_btn_orders: "📦 Orders",
  home_btn_profile: "👤 Profile",
  home_btn_walkin: "🎫 Walk-in Code",
  home_btn_relation: "🤝 B2B Relations",

  # --- Profile ---
  profile_show:
    "👤 *Your Profile*\n\nName: *%{name}*\n🔖 Username: `%{username}`\n📍 Location: *%{location}*\n🌐 Language: *%{lang}*\n⭐ Trust Score: *%{trust_score}*",
  profile_edit_name: "Type your new name:",
  profile_edit_username: "Type your new username:",
  profile_updated: "✅ Profile updated successfully.",

  # --- Market ---
  market_prompt_location: "📍 Share your location first to explore nearby markets.",
  market_no_results: "No stores or products found near you.",
  market_browse_prompt: "What are you looking for?",
  market_btn_find_store: "🔍 Find Store",
  market_btn_find_product: "🔍 Find Product",

  # --- Store ---
  store_no_store: "You don't have a store yet. Create one now?",
  store_btn_create: "🏪 Create Store",
  store_create_name: "What's your store name?",
  store_create_type:
    "Store type:\n- *good* — sell products\n- *service* — sell services\n- *mix* — both",
  store_create_success: "🎉 Store *%{name}* created successfully!",
  store_inactive_warning: "⚠️ Your store is currently inactive.",

  # --- Order ---
  order_empty: "No orders yet.",
  order_created: "✅ Order created. Code: `%{code}`",
  order_confirmed: "✅ Order confirmed by seller.",
  order_cancelled: "❌ Order cancelled.",
  order_pending_seller: "⏳ Waiting for seller confirmation...",
  order_walkin_prompt: "Enter the walk-in order code you received from the seller:",
  order_walkin_invalid: "Code not found or no longer valid.",
  order_walkin_success: "✅ Code accepted! Your order is being processed.",

  # --- Golden Code ---
  golden_notify_confirmed:
    "✅ Your order from *%{store_name}* is confirmed. Your order code: `%{code}` — check for a reward! 🎁",
  golden_reveal_winner:
    "🎉 Congratulations! Code `%{code}` is a *Golden Code* from *%{store_name}*!\n\nYour reward: *%{reward}*\nValid until: *%{deadline}*",
  golden_banner: "🎁 You have an unclaimed reward!",

  # --- Trust Score ---
  trust_score_tier_unverified: "Unverified",
  trust_score_tier_beginner: "Active Beginner",
  trust_score_tier_growing: "Growing Merchant",
  trust_score_tier_reliable: "Reliable Merchant",
  trust_score_tier_master: "Master Merchant",

  # --- Settings ---
  settings_menu: "⚙️ *Settings*",
  settings_lang_prompt: "Choose your language:",
  settings_lang_updated: "✅ Language updated.",
  settings_chat_disabled: "✅ Chat from all sellers has been disabled.",
  settings_chat_enabled: "✅ Chat from all sellers has been re-enabled.",
  settings_reset_confirm: "⚠️ This will clear all your session data. Continue?",
  settings_reset_done: "✅ Session reset successfully.",

  # --- Errors & System ---
  error_gate_l1: "Please register first to use this feature. /register",
  error_gate_l2: "This feature is only available to buyers who have placed an order.",
  error_gate_l3: "This feature is only available to sellers with an active store.",
  error_gate_l4: "This feature is only available to sellers with an active B2B relation.",
  error_unknown_command: "Command not recognized. Type /help to see the list of available commands.",
  error_flow_interrupted:
    "You're currently in the *%{flow}* process.\n\nWould you like to continue or cancel?",
  error_flow_btn_continue: "▶️ Continue",
  error_flow_btn_cancel: "✖️ Cancel",

  # --- About ---
  about_text:
    "*Trenurang* — AI-powered economic infrastructure.\n\nConnecting buyers, sellers, and business partners directly. From local shops to national distribution.",

  # --- Terms ---
  terms_prompt: "By using Trenurang, you agree to our Terms of Service.",
  terms_btn_read: "📄 Read Terms of Service",

  # --- Persona ---
  persona_consent_prompt:
    "May we store some information about your economic activity to help find the right opportunities for you? This data will never be shared without your explicit consent. (UU PDP 2024)",
  persona_consent_btn_yes: "✅ Yes, I Agree",
  persona_consent_btn_no: "❌ Not Now",
  persona_consent_granted:
    "✅ Thank you! We'll start looking for matching opportunities for you.",
}
