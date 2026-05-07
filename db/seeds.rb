[
  { name: 'Alice', accounts: [ { name: 'Main', balance: 1000 }, { name: 'Savings', balance: 500 } ] },
  { name: 'Bob',   accounts: [ { name: 'Main', balance: 1000 }, { name: 'Savings', balance: 500 } ] }
].each do |user_attrs|
  user = User.find_or_create_by!(name: user_attrs[:name])
  user_attrs[:accounts].each do |acc_attrs|
    user.accounts.find_or_create_by!(name: acc_attrs[:name]) do |account|
      account.balance = acc_attrs[:balance]
    end
  end
end

puts "Seeded #{User.count} users with #{Account.count} accounts."
