# encoding: utf-8

require 'spec_helper'

describe Spree::ShippingRate, type: :model do
  let(:shipment) { create(:shipment) }
  let(:shipping_method) { create(:shipping_method) }
  let(:shipping_rate) do
    Spree::ShippingRate.new shipment: shipment,
                            shipping_method: shipping_method,
                            cost: 10
  end

  context "#display_price" do
    context "when tax included in price" do
      let!(:default_zone) { create(:zone, default_tax: true) }
      let(:default_tax_rate) do
        create :tax_rate,
               name: "VAT",
               amount: 0.1,
               included_in_price: true,
               zone: default_zone
      end
      context "when the tax rate is from the default zone" do

        before { shipping_rate.tax_rate = default_tax_rate }

        it "shows correct tax amount" do
          expect(shipping_rate.display_price.to_s).
            to eq("$10.00 (incl. $0.91 #{default_tax_rate.name})")
        end

        context "when cost is zero" do
          before do
            shipping_rate.cost = 0
          end

          it "shows no tax amount" do
            expect(shipping_rate.display_price.to_s).to eq("$0.00")
          end
        end
      end

      context "when the tax rate is from another zone" do
        let!(:non_default_zone) { create(:zone, default_tax: false) }

        let(:non_default_tax_rate) do
          create :tax_rate,
                 name: "VAT",
                 amount: 0.2,
                 included_in_price: true,
                 zone: non_default_zone
        end
        before { shipping_rate.tax_rate = non_default_tax_rate }

        it "deducts the other zone's VAT from the calculated shipping rate" do
          expect(shipping_rate.display_price.to_s).
            to eq("$10.00 (incl. $1.67 #{non_default_tax_rate.name})")
        end

        context "when cost is zero" do
          before do
            shipping_rate.cost = 0
          end

          it "shows no tax amount" do
            expect(shipping_rate.display_price.to_s).to eq("$0.00")
          end
        end
      end
    end

    context "when tax is additional to price" do
      let(:tax_rate) { create(:tax_rate, name: "Sales Tax", amount: 0.1) }
      before { shipping_rate.tax_rate = tax_rate }

      it "shows correct tax amount" do
        expect(shipping_rate.display_price.to_s).
          to eq("$10.00 (+ $1.00 #{tax_rate.name})")
      end

      context "when cost is zero" do
        before do
          shipping_rate.cost = 0
        end

        it "shows no tax amount" do
          expect(shipping_rate.display_price.to_s).to eq("$0.00")
        end
      end
    end

    context "when the currency is JPY" do
      let(:shipping_rate) { Spree::ShippingRate.new(cost: 205) }

      before { allow(shipping_rate).to receive_messages(currency: "JPY") }

      it "displays the price in yen" do
        expect(shipping_rate.display_price.to_s).to eq("¥205")
      end
    end
  end

  # Regression test for #3829
  context "#shipping_method" do
    it "can be retrieved" do
      expect(shipping_rate.shipping_method.reload).to eq(shipping_method)
    end

    it "can be retrieved even when deleted" do
      shipping_method.update_column(:deleted_at, Time.current)
      shipping_rate.save
      shipping_rate.reload
      expect(shipping_rate.shipping_method).to eq(shipping_method)
    end
  end

  context "#tax_rate" do
    let!(:tax_rate) { create(:tax_rate) }

    before do
      shipping_rate.tax_rate = tax_rate
    end

    it "can be retrieved" do
      expect(shipping_rate.tax_rate.reload).to eq(tax_rate)
    end

    it "can be retrieved even when deleted" do
      tax_rate.update_column(:deleted_at, Time.current)
      shipping_rate.save
      shipping_rate.reload
      expect(shipping_rate.tax_rate).to eq(tax_rate)
    end
  end

  describe 'delegate' do
    it { is_expected.to delegate_method(:code).to(:shipping_method).with_prefix(true) }
  end
end
