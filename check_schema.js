const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://eivjgwxyijhfmnyrcbcb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpdmpnd3h5aWpoZm1ueXJjYmNiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNjI3NzgsImV4cCI6MjA4MDkzODc3OH0.iggHHUPjpG6saWEnoJ9WaSDa-rT-FPWjMAnUr7dWfRA';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkSchema() {
  try {
    // Check if we can access bookings table
    console.log('🔍 Checking bookings table schema...\n');

    const { data, error, count } = await supabase
      .from('bookings')
      .select('*', { count: 'exact', head: false })
      .limit(1);

    if (error) {
      console.error('❌ Error accessing bookings table:', error.message);
      console.error('Details:', error);
    } else {
      console.log(`✅ Bookings table exists`);
      console.log(`📊 Row count: ${count}`);
      if (data && data.length > 0) {
        console.log('\n📋 Sample row structure:');
        console.log(Object.keys(data[0]));
      }
    }

    // Try to insert a test booking to check what columns exist
    console.log('\n🔍 Attempting to get table info by checking insert requirements...\n');

    const { error: insertError } = await supabase
      .from('bookings')
      .insert({})
      .select();

    if (insertError) {
      console.log('Column requirements from insert error:');
      console.log(insertError.message);
    }

  } catch (error) {
    console.error('❌ Unexpected error:', error);
  }
}

checkSchema();
