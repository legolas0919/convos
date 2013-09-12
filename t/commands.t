use t::Helper;
use Mojo::JSON;
use Mojo::DOM;

my $dom = Mojo::DOM->new;
my $sub = $t->app->redis->subscribe('wirc:user:doe:irc.perl.org');
my $pub = $t->app->redis;
my $connection = WebIrc::Core::Connection->new(server => 'wirc.pl', login => 'doe');
my $ws;

redis_do(
  [ hmset => 'user:doe', digest => 'E2G3goEIb8gpw', email => '' ],
  [ sadd => 'user:doe:connections', 'irc.perl.org' ],
  [ hmset => 'user:doe:connection:irc.perl.org', nick => 'doe' ],
);

$t->post_ok('/', form => { login => 'doe', password => 'barbar' }) ->status_is(302); # login
$t->websocket_ok('/socket');

{
  $t->send_ok(msg('/query ...'));
  $dom->parse($t->message_ok->message->[1]);
  is $dom->at('li.server-message.error div.content')->text, 'Invalid target: ...', 'Invalid target';

  $t->send_ok(msg('/query marcus'));
  $dom->parse($t->message_ok->message->[1]);
  ok $dom->at('li.add-conversation[data-server="irc.perl.org"][data-target="marcus"]'), 'QUERY marcus';

  $t->send_ok(msg('/query #wirc  '));
  $dom->parse($t->message_ok->message->[1]);
  ok $dom->at('li.add-conversation[data-server="irc.perl.org"][data-target="#wirc"]'), 'QUERY #wirc';
}

{
  $t->send_ok(msg('/help asdasd'));
  $dom->parse($t->message_ok->message->[1]);
  ok $dom->at('li.help[data-target="any"] dl'), 'HELP';
}

{
  $t->send_ok(msg('/help asdasd'));
  $dom->parse($t->message_ok->message->[1]);
  ok $dom->at('li.help[data-target="any"] dl'), 'HELP';
}

{
  publish(event => 'remove_conversation', server => 'irc.perl.org', target => '#wirc');
  $t->send_ok(msg('/close'));
  $dom->parse($t->message_ok->message->[1]);
  is $ws, 'abc-123 PART #wirc', 'abc-123 PART #wirc';
  ok $dom->at('li.remove-conversation[data-server="irc.perl.org"][data-target="#wirc"]'), 'CLOSE';

  $ws = '';
  $t->send_ok(msg('/close   marcus    '));
  $dom->parse($t->message_ok->message->[1]);
  is $ws, '', 'closing a pm will not send a message to backend';
  ok $dom->at('li.remove-conversation[data-server="irc.perl.org"][data-target="marcus"]'), 'CLOSE marcus';
}

{
  local $TODO = 'Need to convert backend to a list';
  $t->send_ok(msg('/reconnect    '));
}

for my $cmd (qw/ j join /) {
  publish(event => 'add_conversation', server => 'irc.perl.org', target => '#toocool');
  $t->send_ok(msg("/$cmd #toocool  "));
  $dom->parse($t->message_ok->message->[1]);
  is $ws, 'abc-123 JOIN #toocool', 'abc-123 JOIN #toocool';
  ok $dom->at('li.add-conversation[data-server="irc.perl.org"][data-target="#toocool"]'), 'JOIN #toocool';
}

for my $cmd (qw/ t topic /) {
  $t->send_ok(msg("/$cmd"));
  is ws(), 'abc-123 TOPIC #wirc', 'abc-123 TOPIP #wirc';

  $t->send_ok(msg("/$cmd yikes!  "));
  is ws(), 'abc-123 TOPIC #wirc :yikes!', 'abc-123 TOPIC #wirc :yikes!';
}

{
  $t->send_ok(msg('/list whatvereasdja n '));
  is ws(), 'abc-123 LIST', 'abc-123 LIST';

  $t->send_ok(msg('/me is too cool :) '));
  is ws(), "abc-123 PRIVMSG #wirc :\x{1}ACTION is too cool :)\x{1}", '/me is too cool :)';

  $t->send_ok(msg('/say /me is cool! '));
  is ws(), "abc-123 PRIVMSG #wirc :/me is cool!", 'PRIVMSG /me is cool!';

  $t->send_ok(msg('/mode +o batman '));
  is ws(), 'abc-123 MODE +o batman', 'abc-123 MODE +o batman';

  $t->send_ok(msg('/names #foo '));
  is ws(), 'abc-123 NAMES #foo', 'abc-123 NAMES #foo';
  $t->send_ok(msg('/names '));
  is ws(), 'abc-123 NAMES #wirc', 'abc-123 NAMES #wirc';

  $t->send_ok(msg('/nick bat '));
  is ws(), 'abc-123 NICK bat', 'abc-123 NICK bat';

  $t->send_ok(msg('/oper toocool 4school '));
  is ws(), 'abc-123 OPER toocool 4school', 'abc-123 OPER toocool 4school';

  $t->send_ok(msg('/part #yikes '));
  is ws(), 'abc-123 PART #yikes', 'abc-123 PART #yikes';
  $t->send_ok(msg('/part      '));
  is ws(), 'abc-123 PART #wirc', 'abc-123 PART #wirc';

  $t->send_ok(msg('/whois batman '));
  is ws(), 'abc-123 WHOIS batman', 'abc-123 WHOIS batman';
}

done_testing;

sub msg {
  qq(<div data-history="1" data-server="irc.perl.org" data-target="#wirc" id="abc-123">$_[0]</div>);
}

sub ws {
  $sub->once(message => sub {
    $ws = $_[1];
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  $ws;
}

sub publish {
  use Mojo::JSON 'j';
  my $data = j { @_ };

  $sub->once(message => sub {
    $ws = $_[1];
    $pub->publish('wirc:user:doe:out', $data);
  });
}
