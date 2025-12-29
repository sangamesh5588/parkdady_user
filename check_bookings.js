const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://eivjgwxyijhfmnyrcbcb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpdmpnd3h5aWpoZm1ueXJjYmNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjI3NzgsImV4cCI6MjA4MDkzODc3OH0.iggHHUPjpG6saWEnoJ9WaSDa-rT-FPWjMAnUr7dWfRA';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkBookings() {
  try {
    console.log('🔍 Checking all bookings in database...\n');

    // Get all bookings
    const { data: allBookings, error: allError } = await supabase
      .from('bookings')
      .select('*');

    if (allError) {
      console.error('❌ Error fetching all bookings:', allError);
      return;
    }

    console.log(`📊 Total bookings in database: ${allBookings?.length || 0}`);

    if (allBookings && allBookings.length > 0) {
      console.log('\n📋 Booking details:');
      allBookings.forEach((booking, index) => {
        console.log(`\n--- Booking ${index + 1} ---`);
        console.log(`ID: ${booking.id}`);
        console.log(`Renter ID: ${booking.renter_id}`);
        console.log(`Listing ID: ${booking.listing_id || 'NULL'}`);
        console.log(`Booking Status: ${booking.booking_status}`);
        console.log(`Payment Status: ${booking.payment_status}`);
        console.log(`Vehicle Type: ${booking.vehicle_type}`);
        console.log(`Booking Date: ${booking.booking_date}`);
        console.log(`Entry Time: ${booking.requested_entry_time}`);
        console.log(`Exit Time: ${booking.requested_exit_time}`);
        console.log(`Base Amount: ${booking.base_amount}`);
        console.log(`Created At: ${booking.created_at}`);
      });
    }

    // Check listings table
    console.log('\n\n🔍 Checking listings table...\n');
    const { data: listings, error: listingsError } = await supabase
      .from('listings')
      .select('id, parking_space_name, parking_address');

    if (listingsError) {
      console.error('❌ Error fetching listings:', listingsError);
    } else {
      console.log(`📊 Total listings in database: ${listings?.length || 0}`);
      if (listings && listings.length > 0) {
        console.log('\n📋 Listing IDs:');
        listings.forEach(listing => {
          console.log(`- ${listing.id}: ${listing.parking_space_name}`);
        });
      }
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

checkBookings();
