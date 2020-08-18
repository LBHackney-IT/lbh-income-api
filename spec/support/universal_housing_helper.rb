module UniversalHousingHelper
  # rubocop:disable Metrics/ParameterLists
  def create_uh_tenancy_agreement(tenancy_ref:, current_balance: 0.0, rent: 5.0, prop_ref: '', terminated: false, cot: '',
                                  tenure_type: 'SEC', high_action: '111', u_saff_rentacc: '', house_ref: '',
                                  nosp_notice_served_date: '1900-01-01 00:00:00 +0000', nosp_notice_expiry_date: '1900-01-01 00:00:00 +0000',
                                  money_judgement: 0.0, charging_order: 0.0, bal_dispute: 0.0, courtdate: '1900-01-01 00:00:00 +0000',
                                  court_outcome: nil, eviction_date: '1900-01-01 00:00:00 +0000', agreement_type: 'M',
                                  service: 0.0, other_charge: 0.0, rentgrp_ref: 'HRA')
    Hackney::UniversalHousing::Client.connection[:tenagree].insert(
      tag_ref: tenancy_ref,
      cur_bal: current_balance,
      rent: rent,
      service: service,
      other_charge: other_charge,
      prop_ref: prop_ref,
      terminated: terminated ? 1 : 0,
      tenure: tenure_type,
      high_action: high_action,
      rentgrp_ref: rentgrp_ref,
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
      u_notice_served: nosp_notice_served_date&.to_date,
      u_notice_expiry: nosp_notice_expiry_date.to_date,
      courtdate: courtdate.to_date,
      u_court_outcome: court_outcome,
      evictdate: eviction_date.to_date,
      intro_date: DateTime.now,
      intro_ext_date: DateTime.now,
      u_saff_rentacc: u_saff_rentacc.to_s + '          ',
      house_ref: house_ref,
      cot: cot,
      u_money_judgement: money_judgement,
      u_charging_order: charging_order,
      u_bal_dispute: bal_dispute,
      agr_type: agreement_type
    )
  end

  def create_uh_agreement(tag_ref:,
                          arag_startdate:,
                          arag_lastcheckbal:,
                          arag_lastcheckdate:,
                          arag_lastexpectedbal:,
                          arag_breached:,
                          arag_startbal:,
                          arag_comment:,
                          aragdet_startdate:,
                          aragdet_amount:,
                          aragdet_comment:,
                          aragdet_frequency:)
    arag_sid = Hackney::UniversalHousing::Client.connection[:arag].count

    Hackney::UniversalHousing::Client.connection[:arag].insert(
      arag_ref: arag_sid,
      arag_sid: arag_sid,
      tag_ref: tag_ref,
      arag_startdate: arag_startdate&.to_date,
      arag_breached: arag_breached,
      arag_lastcheckbal: arag_lastcheckbal,
      arag_lastcheckdate: arag_lastcheckdate&.to_date,
      arag_lastexpectedbal: arag_lastexpectedbal,
      arag_startbal: arag_startbal,
      arag_comment: arag_comment
    )

    Hackney::UniversalHousing::Client.connection[:aragdet].insert(
      arag_sid: arag_sid,
      aragdet_sid: arag_sid,
      aragdet_amount: aragdet_amount,
      aragdet_frequency: aragdet_frequency,
      aragdet_startdate: aragdet_startdate,
      aragdet_enddate: DateTime.now.to_date,
      aragdet_comment: aragdet_comment
    )
  end

  # rubocop:enable Metrics/ParameterLists

  def update_uh_agreement(tag_ref:, aragdet_comment:, aragdet_amount:)
    arag = Hackney::UniversalHousing::Client.connection[:arag].where(tag_ref: tag_ref).first
    aragdet = Hackney::UniversalHousing::Client.connection[:aragdet].where(arag_sid: arag[:arag_sid]).first

    aragdet[:aragdet_sid] += 1000
    aragdet[:aragdet_comment] = aragdet_comment
    aragdet[:aragdet_amount] = aragdet_amount

    Hackney::UniversalHousing::Client.connection[:aragdet].insert(aragdet)
  end

  def create_valid_uh_records_for_an_income_letter(
    property_ref:, house_ref:, postcode:, leasedate:
  )

    create_uh_property(
      property_ref: property_ref,
      post_code: postcode,
      patch_code: 'W02'
    )
    create_uh_tenancy_agreement(
      tenancy_ref: tenancy_ref,
      u_saff_rentacc: payment_ref,
      prop_ref: property_ref,
      house_ref: house_ref,
      current_balance: current_balance
    )
    create_uh_househ(
      house_ref: house_ref,
      prop_ref: property_ref,
      corr_preamble: 'Flat 5 Gingerbread House',
      corr_desig: '98',
      corr_postcode: postcode,
      house_desc: 'Test House Name'
    )
    create_uh_postcode(
      post_code: postcode,
      aline1: 'Fairytale Lane',
      aline2: 'Faraway'
    )
    create_uh_member(
      house_ref: house_ref,
      title: 'Ms',
      forename: 'Fortuna',
      surname: 'Curname'
    )
    create_uh_rent(
      prop_ref: property_ref,
      sc_leasedate: leasedate
    )
  end

  def create_invalid_uh_records_for_an_income_letter(
    property_ref:, house_ref:, postcode:, leasedate:
  )

    create_uh_property(
      property_ref: property_ref,
      post_code: postcode,
      patch_code: 'W02'
    )
    create_uh_tenancy_agreement(
      tenancy_ref: tenancy_ref,
      u_saff_rentacc: payment_ref,
      prop_ref: property_ref,
      house_ref: house_ref,
      current_balance: current_balance
    )
    create_uh_househ(
      house_ref: house_ref,
      prop_ref: property_ref,
      corr_preamble: 'Flat 5 Gingerbread House',
      corr_desig: '98',
      corr_postcode: postcode,
      house_desc: 'Test House Name'
    )
    create_uh_postcode(
      post_code: postcode,
      aline1: 'Fairytale Lane',
      aline2: 'Faraway'
    )
    create_uh_member(
      house_ref: house_ref,
      title: 'Ms',
      forename: '',
      surname: ''
    )
    create_uh_rent(
      prop_ref: property_ref,
      sc_leasedate: leasedate
    )
  end

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

  def create_uh_action(tenancy_ref:, code:, date:, comment: '')
    table = Hackney::UniversalHousing::Client.connection[:araction]
    table.insert(
      tag_ref: tenancy_ref,
      action_code: code,
      action_date: date,
      action_set: 1,
      action_no: (table.max(:action_no) || 0) + 1,
      comm_only: false,
      action_comment: comment
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

  def create_uh_direct_debit(tenancy_ref:, ddagree_status: 399, lu_type: 'DDS', lu_desc:, ddstart: '2020-05-23 00:00:00')
    ddagree_ref = Faker::Number.number(digits: 8).to_s

    Hackney::UniversalHousing::Client.connection[:ddagacc].insert(
      tag_ref: tenancy_ref,
      due_per_period_ta: 1.0,
      ddagree_ref: ddagree_ref,
      current_debits: 0,
      ent_value: 0,
      arag_amount: 0,
      other_dd: 0,
      current_balance: 0,
      total_due: 0,
      fixed_total_due: 0,
      include_balance: 0,
      detail_schedule: 0,
      due_per_period: 0,
      other_rec: 0,
      reduction_cd: 0,
      reduction_ev: 0,
      reduction_od: 0,
      reduction_cb: 0,
      reduction_or: 0,
      reduction_aa: 0,
      smooth_rough: 0
    )
    Hackney::UniversalHousing::Client.connection[:ddagree].insert(
      ddagree_ref: ddagree_ref,
      ddsched_version: 0,
      ddpayer_ref: 'abc',
      ddpayer_type: 'a',
      sort_code: '00-00-00',
      bank_acc: '1234567890',
      ddagree_status: ddagree_status,
      ddperiod: 'abc',
      ddstart: ddstart,
      ddend: '2020-05-23 00:00:00',
      ddcount: 0,
      is_variable: 0,
      ddpayer_notified: '2020-05-23 00:00:00',
      ddsched_date: '2020-05-23 00:00:00',
      ddsched_user: 'abc',
      ddneedsrecalc: 0,
      ddauddis: 0,
      dd_nextref: 'abc',
      bco_ref: 'abc',
      altaccount: 1
    )
    Hackney::UniversalHousing::Client.connection[:lookup].insert(
      lu_ref: ddagree_status,
      lu_type: lu_type,
      lu_desc: lu_desc
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

  def stub_action_diary_write(tenancy_ref:, code:, date:)
    stub_request(
      :post,
      'http://example.com/api/v2/tenancies/arrears-action-diary'
    ).to_return(lambda do |request|
      json_body = JSON.parse(request.body)

      # Mock the behaviour of the API by writing directly to UH
      create_uh_action(
        tenancy_ref: json_body['tenancyAgreementRef'],
        code: json_body['actionCode'],
        date: Time.zone.parse(json_body['createdDate']),
        comment: json_body['comment']
      )

      { status: 200, body: '', headers: {} }
    end)
  end

  def truncate_uh_tables
    Hackney::UniversalHousing::Client.connection[:tenagree].truncate
    Hackney::UniversalHousing::Client.connection[:rtrans].truncate
    Hackney::UniversalHousing::Client.connection[:arag].truncate
    Hackney::UniversalHousing::Client.connection[:aragdet].truncate
    Hackney::UniversalHousing::Client.connection[:araction].truncate
    Hackney::UniversalHousing::Client.connection[:property].truncate
    Hackney::UniversalHousing::Client.connection[:househ].truncate
    Hackney::UniversalHousing::Client.connection[:postcode].truncate
    Hackney::UniversalHousing::Client.connection[:rent].truncate
    Hackney::UniversalHousing::Client.connection[:u_letsvoids].truncate
    Hackney::UniversalHousing::Client.connection[:member].truncate
    Hackney::UniversalHousing::Client.connection[:ddagacc].truncate
    Hackney::UniversalHousing::Client.connection[:ddagree].truncate
    Hackney::UniversalHousing::Client.connection[:lookup].truncate
  end
end
