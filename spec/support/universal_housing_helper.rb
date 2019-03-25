module UniversalHousingHelper
  def create_uh_tenancy_agreement(tenancy_ref:, current_balance: 0.0, property_ref: '', terminated: false, tenure_type: 'SEC', high_action: '111')
    Hackney::UniversalHousing::Client.connection[:tenagree].insert(
      tag_ref: tenancy_ref,
      cur_bal: current_balance,
      prop_ref: property_ref,
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
      intro_date: DateTime.now,
      intro_ext_date: DateTime.now
    )
  end

  def create_uh_tenancy_agreement_with_property(
    tenancy_ref:, current_balance: 0.0, prop_ref: '', arr_patch: '', terminated: false, tenure_type: 'SEC', high_action: '111'
  )
    create_uh_property(property_ref: prop_ref, patch_code: arr_patch)
    create_uh_tenancy_agreement(
      tenancy_ref: tenancy_ref,
      current_balance: current_balance,
      property_ref: prop_ref,
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

  def create_uh_arrears_agreement(tenancy_ref:, status:)
    Hackney::UniversalHousing::Client.connection[:arag].insert(
      arag_ref: Faker::IDNumber.valid,
      tag_ref: tenancy_ref,
      arag_status: status,
      arag_breached: false
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

  def create_uh_property(property_ref:, patch_code:)
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
      dtstamp: DateTime.now
    )
  end

  def truncate_uh_tables
    Hackney::UniversalHousing::Client.connection[:tenagree].truncate
    Hackney::UniversalHousing::Client.connection[:rtrans].truncate
    Hackney::UniversalHousing::Client.connection[:arag].truncate
    Hackney::UniversalHousing::Client.connection[:araction].truncate
    Hackney::UniversalHousing::Client.connection[:property].truncate
  end
end
