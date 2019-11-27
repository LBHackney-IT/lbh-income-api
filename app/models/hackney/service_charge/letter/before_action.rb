module Hackney
  module ServiceCharge
    class Letter
      class BeforeAction < Hackney::ServiceCharge::Letter
        TEMPLATE_PATHS = [
          'lib/hackney/pdf/templates/leasehold/letter_before_action.erb'
        ].freeze
        MANDATORY_FIELDS = %i[original_lease_date date_of_current_purchase_assignment money_judgement].freeze

        def initialize(params)
          super(params)
          
          validated_params = validate_mandatory_fields(MANDATORY_FIELDS, params)

          @lba_expiry_date = validated_params[:lba_expiry_date]
          @original_lease_date = format_date(validated_params[:original_lease_date])
          @date_of_current_purchase_assignment = validated_params[:date_of_current_purchase_assignment]
          @original_leaseholders = 'the original leaseholder' # Placeholder - field does not exist within UH yet
          @lba_balance = format('%.2f', calculate_lba_balance(
                                          validated_params[:total_collectable_arrears_balance],
                                          validated_params[:money_judgement]
                                        ))
          @tenure_type = validated_params[:tenure_type]
          validate_lba_balance_exists?
        end

        def freehold?
          @tenure_type == Hackney::Income::Domain::TenancyAgreement::TENURE_TYPE_FREEHOLD
        end

        private

        def calculate_lba_balance(arrears_balance, money_judgement)
          if arrears_balance.nil?	
            arrears_balance = 0	
          elsif money_judgement.nil?	
            money_judgement = 0	
          end
          BigDecimal(arrears_balance.to_s) - BigDecimal(money_judgement.to_s)
        end

        def format_date(date)
          return nil if date.nil?

          date.strftime('%d %B %Y')
        end

        def validate_lba_balance_exists?
          @errors.cocncat(name: @lba_balance.to_s, message: 'missing mandatory field') if @lba_balance.nil?
        end
      end
    end
  end
end
