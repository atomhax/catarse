require 'spec_helper'

describe BackerObserver do
  let(:confirm_backer){ Factory(:notification_type, :name => 'confirm_backer') }
  let(:backer){ Factory(:backer, :key => 'should be updated', :payment_method => 'should be updated', :confirmed => true, :confirmed_at => nil) }
  subject{ backer }

  before do
    confirm_backer # It should create the NotificationType before creating the Backer
  end

  describe "after_create" do
    before{ Kernel.stubs(:rand).returns(1) }
    its(:key){ should == Digest::MD5.new.update("#{backer.id}###{backer.created_at}##1").to_s }
    its(:payment_method){ should == 'MoIP' }
  end

  describe "before_save" do
    context "when payment_choice is updated to BoletoBancario" do
      let(:backer){ Factory(:backer, :key => 'should be updated', :payment_method => 'should be updated', :confirmed => true, :confirmed_at => Time.now) }
      before do
        Notification.expects(:notify_backer).with(backer, :payment_slip)
        backer.payment_choice = 'BoletoBancario'
        backer.save!
      end
      it("should notify the backer"){ subject }
    end

    context "when is not yet confirmed" do
      before do 
        Notification.expects(:notify_backer).with(backer, :confirm_backer)
      end
      its(:confirmed_at) { should_not be_nil }
    end

    context "when is already confirmed" do
      let(:backer){ Factory(:backer, :key => 'should be updated', :payment_method => 'should be updated', :confirmed => true, :confirmed_at => Time.now) }
      before do 
        Notification.expects(:notify_backer).never
      end

      it("should not send confirm_backer notification again"){ subject }
    end
  end
end
