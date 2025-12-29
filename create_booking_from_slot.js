const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://eivjgwxyijhfmnyrcbcb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpdmpnd3h5aWpoZm1ueXJjYmNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjI3NzgsImV4cCI6MjA4MDkzODc3OH0.iggHHUPjpG6saWEnoJ9WaSDa-rT-FPWjMAnUr7dWfRA';

const supabase = createClient(supabaseUrl, supabaseKey, {
  global: {
    fetch: (...args) => fetch(...args),
  },
  db: {
    schema: 'public'
  }
});

async function createBookingFromSlot() {
  try {
    console.log('🔍 Step 1: Fetching parking active slot data...\n');

    // Get the parking active slot
    const { data: slot, error: slotError } = await supabase
      .from('parking_active_slots')
      .select('*')
      .limit(1)
      .single();

    if (slotError) {
      console.error('❌ Error fetching parking slot:', slotError.message);
      return;
    }

    console.log('✅ Found parking slot:');
    console.log('  - Slot ID:', slot.id);
    console.log('  - Listing ID:', slot.listing_id);
    console.log('  - Date:', slot.date);
    console.log('  - Car Slots:', slot.active_car_slots);
    console.log('  - Bike Slots:', slot.active_bike_slots);
    console.log('  - Created:', slot.created_at);

    // Get the listing details
    console.log('\n🔍 Step 2: Fetching listing details...\n');

    const { data: listing, error: listingError } = await supabase
      .from('listings')
      .select('*')
      .eq('id', slot.listing_id)
      .single();

    if (listingError) {
      console.error('❌ Error fetching listing:', listingError.message);
      return;
    }

    console.log('✅ Found listing:');
    console.log('  - Listing ID:', listing.id);
    console.log('  - Name:', listing.parking_space_name);
    console.log('  - Address:', listing.parking_address);
    console.log('  - Car Rate: ₹' + listing.hourly_rate_car + '/hr');
    console.log('  - Bike Rate: ₹' + listing.hourly_rate_bike + '/hr');
    console.log('  - Host ID:', listing.host_id);

    // Get current authenticated user
    console.log('\n🔍 Step 3: Getting current user...\n');

    const { data: { user }, error: userError } = await supabase.auth.getUser();

    let renterId;
    if (userError || !user) {
      console.log('⚠️  No authenticated user, using host as renter for testing');
      renterId = listing.host_id;
    } else {
      console.log('✅ Found user:', user.email);
      renterId = user.id;
    }

    // Create booking with the slot data
    console.log('\n📝 Step 4: Creating booking...\n');

    const bookingDate = slot.date; // Use the date from the parking slot
    const entryTime = '10:00:00';
    const exitTime = '14:00:00';
    const durationHours = 4;
    const vehicleType = 'car'; // Using car for this booking
    const baseAmount = listing.hourly_rate_car * durationHours; // ₹73 * 4 = ₹292
    const platformFee = 9.0;

    const bookingData = {
      listing_id: listing.id,
      renter_id: renterId,
      host_id: listing.host_id,
      vehicle_type: vehicleType,
      booking_date: bookingDate,
      requested_entry_time: entryTime,
      requested_exit_time: exitTime,
      duration_hours: durationHours,
      base_amount: baseAmount,
      original_amount: baseAmount,
      platform_fee: platformFee,
      discount_amount: 0,
      discount_percent: 0,
      extra_amount: 0,
      extra_minutes: 0,
      grace_period_minutes: 10,
      payment_status: 'paid',
      payment_method: 'UPI',
      booking_status: 'pending',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    console.log('📋 Booking details:');
    console.log('  - Listing:', listing.parking_space_name);
    console.log('  - Date:', bookingDate);
    console.log('  - Time:', entryTime, '-', exitTime, '(' + durationHours + ' hours)');
    console.log('  - Vehicle:', vehicleType.toUpperCase());
    console.log('  - Rate: ₹' + listing.hourly_rate_car + '/hr');
    console.log('  - Base Amount: ₹' + baseAmount);
    console.log('  - Platform Fee: ₹' + platformFee);
    console.log('  - Total: ₹' + (baseAmount + platformFee));
    console.log('  - Status:', bookingData.booking_status);
    console.log('  - Payment:', bookingData.payment_status);

    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .insert(bookingData)
      .select()
      .single();

    if (bookingError) {
      console.error('\n❌ Error creating booking:', bookingError.message);
      console.error('Error details:', bookingError);
      return;
    }

    console.log('\n✅ Booking created successfully!');
    console.log('  - Booking ID:', booking.id);

    // Verify the booking with listing data (like the app does)
    console.log('\n🔍 Step 5: Verifying booking (with listing join)...\n');

    const { data: verifyData, error: verifyError } = await supabase
      .from('bookings')
      .select(`
        *,
        listings (
          parking_space_name,
          parking_address,
          latitude,
          longitude,
          hourly_rate_car,
          hourly_rate_bike
        )
      `)
      .eq('id', booking.id)
      .single();

    if (verifyError) {
      console.error('❌ Error verifying:', verifyError.message);
    } else {
      console.log('✅ Verified! Booking with listing data retrieved successfully');
      console.log('\n📦 Complete booking object:');
      console.log(JSON.stringify(verifyData, null, 2));
    }

    console.log('\n🎉 SUCCESS! Now restart your app and check the "My Bookings" screen!');
    console.log('   The booking should appear in the "Active" tab.');

  } catch (error) {
    console.error('\n❌ Unexpected error:', error);
  }
}

createBookingFromSlot();
