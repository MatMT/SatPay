-- Reference data for the simulator. Rates are static mocks, not market data.

insert into public.currencies (code, name, symbol, kind, decimals) values
  ('USD', 'US Dollar',       '$',   'fiat',    2),
  ('EUR', 'Euro',            '€',   'fiat',    2),
  ('MXN', 'Mexican Peso',    '$',   'fiat',    2),
  ('COP', 'Colombian Peso',  '$',   'fiat',    2),
  ('SAT', 'Satoshi',         'sat', 'bitcoin', 0),
  ('BTC', 'Bitcoin',         '₿',   'bitcoin', 8)
on conflict (code) do nothing;

-- Mock BTC price of 100,000 USD => 1 USD = 1,000 sats.
insert into public.exchange_rates (base_currency, quote_currency, rate, source) values
  ('USD', 'SAT', 1000,        'static'),
  ('USD', 'BTC', 0.00001,     'static'),
  ('USD', 'EUR', 0.92,        'static'),
  ('USD', 'MXN', 17.50,       'static'),
  ('USD', 'COP', 4000,        'static'),
  ('SAT', 'USD', 0.001,       'static'),
  ('EUR', 'USD', 1.0869565217,'static'),
  ('MXN', 'USD', 0.0571428571,'static'),
  ('COP', 'USD', 0.00025,     'static');

-- 1.5% + 0.50 fixed, minimum 1.00 (applied in the send currency).
insert into public.fee_rules (currency, percent_fee, fixed_fee, min_fee) values
  ('USD', 0.015, 0.50, 1.00),
  ('EUR', 0.015, 0.50, 1.00),
  ('MXN', 0.015, 10,   20),
  ('COP', 0.015, 2000, 4000),
  ('SAT', 0.010, 500,  1000);
