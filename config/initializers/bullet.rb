if defined?(Bullet)
  # False positive: when an account is loaded both via `current_user.accounts`
  # (which sets inverse_of for :user) and via `Order.includes(... :user)`,
  # Bullet's inverse-of guard suppresses the call registration on the second
  # object, making the legitimately-used preload look unused.
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Account', association: :user
end
