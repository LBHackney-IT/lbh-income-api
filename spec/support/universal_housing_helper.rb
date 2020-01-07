module UniversalHousingHelper
  # rubocop:disable Metrics/ParameterLists
  def create_uh_tenancy_agreement(tenancy_ref:, current_balance: 0.0, rent: 5.0, prop_ref: '', terminated: false, cot: '',
                                  tenure_type: 'SEC', high_action: '111', u_saff_rentacc: '', house_ref: '',
                                  nosp_notice_served_date: '1900-01-01 00:00:00 +0000', nosp_notice_expiry_date: '1900-01-01 00:00:00 +0000',
                                  money_judgement: 0.0, charging_order: 0.0, bal_dispute: 0.0, courtdate: '1900-01-01 00:00:00 +0000',
                                  court_outcome: nil, eviction_date: '1900-01-01 00:00:00 +0000', agreement_type: 'M')
    Hackney::UniversalHousing::Client.connection[:tenagree].insert(
      tag_ref: tenancy_ref,
      cur_bal: current_balance,
      rent: rent,
      prop_ref: prop_ref,
      terminated: terminated ? 1 : 0,
      tenure: tenure_type,
      high_action: high_action,
      spec_terms: true,
      other_accounts: false,
      active: true,
      present: true,
      free_active: false,
      nop: false,
      additional_debit: false,
      hb_freq: '?',
      receiptcard: false,
      nosp: false,
      ntq: false,
      eviction: false,
      committee: false,
      suppossorder: false,
      possorder: false,
      courtapp: false,
      open_item: true,
      fd_charge: false,
      potentialenddate: DateTime.now,
      u_payment_expected: '?',
      dtstamp: DateTime.now,
      u_notice_served: nosp_notice_served_date.to_date,
      u_notice_expiry: nosp_notice_expiry_date.to_date,
      courtdate: courtdate.to_date,
      u_court_outcome: court_outcome,
      evictdate: eviction_date.to_date,
      intro_date: DateTime.now,
      intro_ext_date: DateTime.now,
      u_saff_rentacc: u_saff_rentacc,
      house_ref: house_ref,
      cot: cot,
      u_money_judgement: money_judgement,
      u_charging_order: charging_order,
      u_bal_dispute: bal_dispute,
      agr_type: agreement_type
    )
  end
  # rubocop:enable Metrics/ParameterLists

  def create_uh_tenancy_agreement_with_property(
    tenancy_ref:, current_balance: 0.0, prop_ref: '', arr_patch: '', terminated: false, tenure_type: 'SEC', high_action: '111'
  )
    create_uh_property(property_ref: prop_ref, patch_code: arr_patch)
    create_uh_tenancy_agreement(
      tenancy_ref: tenancy_ref,
      current_balance: current_balance,
      prop_ref: prop_ref,
      terminated: terminated,
      tenure_type: tenure_type,
      high_action: high_action
    )
  end

  def create_uh_transaction(tenancy_ref:, amount: 0.0, date: Date.today, type: '')
    Hackney::UniversalHousing::Client.connection[:rtrans].insert(
      tag_ref: tenancy_ref,
      real_value: amount,
      post_date: date,
      trans_type: type,
      batchid: rand(1..100_000),
      batchno: 1.0,
      transno: 1,
      line_no: 1,
      adjustment: false,
      apportion: false,
      prop_deb: false,
      none_rent: false,
      receipted: 0.0,
      line_segno: false,
      vat: false
    )
  end

  def create_uh_arrears_agreement(tenancy_ref:, status:, status_entry_date: nil, expected_balance: nil, agreement_start_date: nil)
    Hackney::UniversalHousing::Client.connection[:arag].insert(
      arag_ref: Faker::IDNumber.valid,
      tag_ref: tenancy_ref,
      arag_status: status,
      arag_breached: false,
      arag_statusdate: status_entry_date,
      arag_lastexpectedbal: expected_balance,
      arag_startdate: agreement_start_date
    )
  end

  def create_uh_action(tenancy_ref:, code:, date:)
    Hackney::UniversalHousing::Client.connection[:araction].insert(
      tag_ref: tenancy_ref,
      action_code: code,
      action_date: date,
      action_set: 1,
      action_no: 1,
      comm_only: false
    )
  end

  def create_uh_property(property_ref:, patch_code: '', post_preamble: '', address1: '', post_code: '', post_desig: '')
    Hackney::UniversalHousing::Client.connection[:property].insert(
      prop_ref: property_ref,
      arr_patch: patch_code,
      managed_property: false,
      ownership: 'required field',
      letable: true,
      lounge: false,
      laundry: false,
      visitor_bed: false,
      store: false,
      warden_flat: false,
      sheltered: true,
      shower: true,
      rtb: false,
      core_shared: false,
      asbestos: false,
      no_single_beds: 1,
      no_double_beds: 1,
      online_repairs: true,
      repairable: true,
      dtstamp: DateTime.now,
      post_preamble: post_preamble,
      address1: address1,
      post_code: post_code,
      post_desig: post_desig
    )
  end

  def create_uh_househ(house_ref:, prop_ref: '', corr_preamble: '', corr_desig: '', post_code: '', corr_postcode: '', house_desc: '')
    Hackney::UniversalHousing::Client.connection[:househ].insert(
      house_ref: house_ref,
      prop_ref: prop_ref,
      corr_preamble: corr_preamble,
      u_prev_br: '',
      assn_address: '',
      joint_ten: 0,
      oap: 0,
      fair_rights: 0,
      protected_rights: 0,
      house_size: 0,
      info_refused: '',
      auto_housedesc: '',
      u_tranreq: '',
      vulnerable: '',
      full_ed: '',
      u_mutual_exchange: '',
      u_prev_kit: '',
      corr_desig: corr_desig,
      post_code: post_code,
      corr_postcode: corr_postcode,
      house_desc: house_desc
    )
  end

  def create_uh_postcode(post_code:, aline1:, aline2: '', aline3: '', aline4: '')
    Hackney::UniversalHousing::Client.connection[:postcode].insert(
      post_code: post_code,
      aline1: aline1,
      aline2: aline2,
      aline3: aline3,
      aline4: aline4,
      ci_post_code: ''
    )
  end

  def create_uh_rent(prop_ref:, sc_leasedate:)
    Hackney::UniversalHousing::Client.connection[:rent].insert(
      prop_ref: prop_ref,
      sc_leasedate: sc_leasedate,
      affordable_rent: '',
      autoavail: '',
      avail_on_alloc: '',
      avail: '',
      used: '',
      wheelchair: '',
      free_active: '',
      mobility: '',
      furnished: '',
      sharedowner: 0,
      localletting: '',
      insurevalue: '',
      valuation: '',
      estvalue: '',
      actvalue: '',
      valuedate: '',
      rtbelig: ''
    )
  end

  def create_uh_u_letsvoids(payment_ref:, prop_ref:)
    Hackney::UniversalHousing::Client.connection[:u_letsvoids].insert(
      payment_ref: payment_ref,
      prop_ref: prop_ref
    )
  end

  def create_uh_member(house_ref:, title:, forename:, surname:)
    Hackney::UniversalHousing::Client.connection[:member].insert(
      house_ref: house_ref,
      title: title,
      forename: forename,
      surname: surname,
      person_no: 1,
      oap: 0,
      responsible: 0,
      at_risk: 0,
      full_ed: 0,
      member_sid: 0,
      dob: DateTime.now,
      bank_acc_type: 'BANK'
    )
  end

  def truncate_uh_tables
    Hackney::UniversalHousing::Client.connection[:tenagree].truncate
    Hackney::UniversalHousing::Client.connection[:rtrans].truncate
    Hackney::UniversalHousing::Client.connection[:arag].truncate
    Hackney::UniversalHousing::Client.connection[:araction].truncate
    Hackney::UniversalHousing::Client.connection[:property].truncate
    Hackney::UniversalHousing::Client.connection[:househ].truncate
    Hackney::UniversalHousing::Client.connection[:postcode].truncate
    Hackney::UniversalHousing::Client.connection[:rent].truncate
    Hackney::UniversalHousing::Client.connection[:u_letsvoids].truncate
    Hackney::UniversalHousing::Client.connection[:member].truncate
  end
end
