Doorkeeper::Application.create!(name: 'Web', superapp: true, redirect_uri: Doorkeeper.configuration.native_redirect_uri, scopes: 'read write follow')

if Rails.env.development?
  domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
  admin  = Account.where(username: 'admin').first_or_initialize(username: 'admin')
  admin.save(validate: false)
  User.where(email: "admin@#{domain}").first_or_initialize(email: "admin@#{domain}", password: 'mastodonadmin', password_confirmation: 'mastodonadmin', confirmed_at: Time.now.utc, admin: true, account: admin).save!

  accounts = 20.times.map { |i| Account.where(username: "test#{i}").first_or_create!(username: "test#{i}") }
  accounts.each do |account|
    User.where(email: "#{account.username}@#{domain}").first_or_initialize(email: "#{account.username}@#{domain}", password: 'mastodonadmin', password_confirmation: 'mastodonadmin', confirmed_at: Time.now.utc, admin: false, account: account).save!
  end

  if admin.statuses.empty? then
    statuses = 50.times.map { |i| PostStatusService.new.call(admin, i.to_s)}
    statuses.take(10).each { |s| FavouriteService.new.call(accounts[2], s)}
    statuses.drop(10).take(2).each { |s| ReblogService.new.call(accounts[2], s)}

    prev = PostStatusService.new.call(accounts[3], 'hello')
    prev = PostStatusService.new.call(accounts[4], 'reply', prev)
    PostStatusService.new.call(accounts[3], 'again', prev)

    PostStatusService.new.call(accounts[5], '@admin mention')
    PostStatusService.new.call(accounts[5], '@admin direct', nil, visibility: 'direct')
  end
end
