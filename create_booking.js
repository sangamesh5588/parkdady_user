const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://eivjgwxyijhfmnyrcbcb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpdmpnd3h5aWpoZm1ueXJjYmNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjI3NzgsImV4cCI6MjA4MDkzODc3OH0.iggHHUPjpG6saWEnoJ9WaSDa-rT-FPWjMAnUr7dWfRA';

const supabase = createClient(supabaseUrl, supabaseKey);

async function createBooking() {
  try {
    // First, get the listing details
    console.log('🔍 Fetching listing details...\n');

    const { data: listing, error: listingError } = await supabase
      .from('listings')
      .select('*')
      .eq('parking_space_name', 'sangu')
      .single();

    if (listingError) {
      console.error('❌ Error fetching listing:', listingError);
      return;
    }

    console.log('✅ Found listing:');
    console.log('  - ID:', listing.id);
    console.log('  - Name:', listing.parking_space_name);
    console.log('  - Address:', listing.parking_address);
    console.log('  - Car Rate: ₹' + listing.hourly_rate_car + '/hr');
    console.log('  - Bike Rate: ₹' + listing.hourly_rate_bike + '/hr');
    console.log('  - Host ID:', listing.host_id);

    // Get current user (we need to authenticate first or use a known user ID)
    // For now, let's use the host_id as the renter_id for testing
    const renterId = listing.host_id; // In production, this should be the actual logged-in user

    // Create a booking
    console.log('\n📝 Creating booking...\n');

    const bookingDate = new Date().toISOString().split('T')[0]; // Today's date (YYYY-MM-DD)
    const entryTime = '10:00:00';
    const exitTime = '14:00:00';
    const durationHours = 4;
    const baseAmount = listing.hourly_rate_car * durationHours; // Using car rate
    const platformFee = 9.0;

    const bookingData = {
      listing_id: listing.id,
      renter_id: renterId,
      host_id: listing.host_id,
      vehicle_type: 'car',
      booking_date: bookingDate,
      requested_entry_time: entryTime,
      requested_exit_time: exitTime,
      duration_hours: durationHours,
      base_amount: baseAmount,
      original_amount: baseAmount,
      platform_fee: platformFee,
      payment_status: 'paid',
      payment_method: 'UPI',
      booking_status: 'pending',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    console.log('Booking data:');
    console.log('  - Listing ID:', bookingData.listing_id);
    console.log('  - Renter ID:', bookingData.renter_id);
    console.log('  - Vehicle Type:', bookingData.vehicle_type);
    console.log('  - Date:', bookingData.booking_date);
    console.log('  - Time:', entryTime, '-', exitTime);
    console.log('  - Duration:', durationHours, 'hours');
    console.log('  - Base Amount: ₹' + baseAmount);
    console.log('  - Platform Fee: ₹' + platformFee);
    console.log('  - Total: ₹' + (baseAmount + platformFee));

    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .insert(bookingData)
      .select()
      .single();

    if (bookingError) {
      console.error('\n❌ Error creating booking:', bookingError.message);
      console.error('Details:', bookingError);
      return;
    }

    console.log('\n✅ Booking created successfully!');
    console.log('Booking ID:', booking.id);
    console.log('\n🎉 You should now see this booking in your app!');

    // Verify the booking with joined data
    console.log('\n🔍 Verifying booking with listing data...\n');

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
      console.error('❌ Error verifying:', verifyError);
    } else {
      console.log('✅ Verified! Booking with listing data:');
      console.log(JSON.stringify(verifyData, null, 2));
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

createBooking();
