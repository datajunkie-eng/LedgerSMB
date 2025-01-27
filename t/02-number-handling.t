#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;

use LedgerSMB::Form;
use LedgerSMB::PGNumber;
use LedgerSMB::App_State;

use Math::BigFloat;
use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init($OFF);


my $form = Form->new;
my %myconfig;
ok(defined $form);
isa_ok($form, 'Form');


LedgerSMB::App_State::set_User(\%myconfig);
like(
    dies { $form->format_amount({'apples' => '1000.00'}, 'foo', 2) },
    qr/LedgerSMB::PGNumber No Format Set/,
    'lsmb: No numberformat set, invalid amount message (NaN check)');
my  $expected;
# foreach my $value (
#     '0.01', '0.05', '0.015', '0.025', '1.1', '1.5', '1.9',
#     '10.01', '4', '5', '5.1', '5.4', '5.5', '5.6', '6', '0',
#     '0.000', '10.155', '55', '0.001', '14.5', '15.5', '4.5'
# ) {
#     foreach my $places ('3', '2', '1', '0') {
#         Math::BigFloat->round_mode('+inf');
#         $expected = Math::BigFloat->new($value)->ffround(-$places);
#         $expected->precision(undef);
#         is($form->round_amount($value, $places), $expected,
#            "form: $value to $places decimal places - $expected");

#         Math::BigFloat->round_mode('-inf');
#         $expected = Math::BigFloat->new(-$value)->ffround(-$places);
#         $expected->precision(undef);
#         is($form->round_amount(-$value, $places), $expected,
#            "form: -$value to $places decimal places - $expected");
#     }
#     foreach my $places ('-1', '-2') {
#         Math::BigFloat->round_mode('+inf');
#         $expected = Math::BigFloat->new($value)->ffround(-($places-1));
#         ok($form->round_amount($value, $places) == $expected,
#            "form: $value to $places decimal places - $expected");

#         Math::BigFloat->round_mode('-inf');
#         $expected = Math::BigFloat->new(-$value)->ffround(-($places-1));
#         ok($form->round_amount(-$value, $places) == $expected,
#            "form: -$value to $places decimal places - $expected");
#     }
# }

# TODO Number formatting still needs work for l10n
my @formats = (#['1,000.00', ',', '.'], ["1'000.00", "'", '.'],
    ['1.000,00', '.', ','], ['1000,00', '', ','],);
    #['1000.00', '', '.'], ['1 000.00', ' ', '.']);
my %myfooconfig = (numberformat => '1000.00');
my $test_args = {
    format => 0,
    places => 2,
    neg_format => 'def',
};
foreach my $format (0 .. $#formats) {
    %myconfig = (numberformat => $formats[$format][0]);
    $LedgerSMB::App_State::User = \%myconfig;
    $test_args->{format} = $formats[$format][0];
    my $thou = $formats[$format][1];
    my $dec = $formats[$format][2];
    foreach my $rawValue (#'10t000d00', '9t999d99', '333d33',
                           '7t777t777d77', '-12d34', '0d00') {
        $expected = $rawValue;
        $expected =~ s/t/$thou/gx;
        $expected =~ s/d/$dec/gx;
        my $value = $rawValue;
        $value =~ s/t//gx;
        $value =~ s/d/\./gx;
        $value = LedgerSMB::PGNumber->from_db($value);
        is(LedgerSMB::PGNumber->from_input($value, $test_args
            )->to_output($test_args),
            $expected,
            "Pgnumber: $value formatted as $test_args->{format} : $expected");
        is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
            "form: $value formatted as $formats[$format][0] : $expected");
    }
}

foreach my $format (0 .. $#formats) {
    %myconfig = (numberformat => $formats[$format][0]);
    $LedgerSMB::App_State::User = \%myconfig;
    my $thou = $formats[$format][1];
    my $dec = $formats[$format][2];
    foreach my $rawValue ('10t000d00', '9t999d99', '333d33',
                          '7t777t777d77', '-12d34', '0d00') {
        $expected = $rawValue;
        $expected =~ s/t/$thou/gx;
        $expected =~ s/d/$dec/gx;
        my $value = $rawValue;
        $value =~ s/t//gx;
        $value =~ s/d/\./gx;
        my $val2 = $value;
        ##$value = Math::BigFloat->new($value);
        $value = $form->parse_amount(\%myfooconfig,$value);
        is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
            "form: $value formatted as $formats[$format][0] - $expected");
    }
}

foreach my $format (0 .. $#formats) {
    %myconfig = (numberformat => $formats[$format][0]);
    $LedgerSMB::App_State::User = \%myconfig;
    my $thou = $formats[$format][1];
    my $dec = $formats[$format][2];
    my $rawValue = '6d00';
    $expected = $rawValue;
    $expected =~ s/d/$dec/gx;
    my $value = $form->parse_amount(\%myfooconfig, '6');
    is($form->format_amount(\%myconfig, $value, 2, '0'), $expected,
        "form: $value formatted as $formats[$format][0] - $expected");
}

$expected = $form->parse_amount({'numberformat' => '1000.00'}, '0.00');
is($form->format_amount({'numberformat' => '1000.00'} , $expected, 2, ''), '0.00',
    "form: 0.00 with dash ''");
is($form->format_amount({'numberformat' => '1000.00'} , $expected, 2), '0.00',
    "form: 0.00 with undef dash");
$ENV{GATEWAY_INTERFACE} = 'yes';
$form->{pre} = 'Blah';
$form->{header} = 'Blah';
is($form->format_amount({'numberformat' => '1000.00'} , '-1.00', 2, 'paren'), '(1.00)',
    "form: -1.00 with dash '-'");
is($form->format_amount({'numberformat' => '1000.00'} , '1.00', 2, 'paren'), '1.00',
    "form: 1.00 with dash '-'");
is($form->format_amount({'numberformat' => '1000.00'} , '-1.00', 2, 'DRCR'),
    '1.00 DR', "form: -1.00 with dash DRCR");
is($form->format_amount({'numberformat' => '1000.00'} , '1.00', 2, 'DRCR'),
    '1.00 CR', "form: 1.00 with dash DRCR");
is($form->format_amount({'numberformat' => '1000.00'} , '-1.00', 2), '-1.00',
    "form: -1.00 with dash undefined");
is($form->format_amount({'numberformat' => '1000.00'} , '1.00', 2), '1.00',
    "form: 1.00 with dash undefined");
# Triggers the $amount .= "\.$dec" if ($dec ne ""); check to false
is($form->format_amount({'numberformat' => '1000.00'} , '1.00'), '1',
    "form: 1.00 with no precision or dash (1000.00)");
is($form->format_amount({'numberformat' => '1,000.00'} , '1.00'), '1',
    "form: 1.00 with no precision or dash (1,000.00)");
is($form->format_amount({'numberformat' => '1 000.00'} , '1.00'), '1',
    "form: 1.00 with no precision or dash (1 000.00)");
is($form->format_amount({'numberformat' => '1\'000.00'} , '1.00'), '1',
    "form: 1.00 with no precision or dash (1'000.00)");
is($form->format_amount({'numberformat' => '1.000,00'} , '1,00'), '1',
    "form: 1,00 with no precision or dash (1.000,00)");
is($form->format_amount({'numberformat' => '1000,00'} , '1,00'), '1',
    "form: 1,00 with no precision or dash (1000,00)");
is($form->format_amount({'numberformat' => '1000.00'} , '1.50'), '1.5',
    "form: 1.50 with no precision or dash");
is($form->format_amount({'numberformat' => '1000.00'} , '0.0', undef, '0'), '0',
    "form: 0.0 with no precision, dash '0'");

foreach my $format (0 .. $#formats) {
    %myconfig = (numberformat => $formats[$format][0]);
    $LedgerSMB::App_State::User = \%myconfig;
    my $thou = $formats[$format][1];
    my $dec = $formats[$format][2];
    foreach my $rawValue ('10t000d00', '9t999d99', '333d33',
                          '7t777t777d77', '-12d34') {
        $expected = $rawValue;
        $expected =~ s/t/$thou/gx;
        $expected =~ s/d/$dec/gx;
        my $value = $rawValue;
        $value =~ s/t//gx;
        $value =~ s/d/\./gx;
        #my $ovalue = $value;
        $value = $form->parse_amount(\%myfooconfig,$value);
        is($form->format_amount(\%myconfig,
            $form->format_amount(\%myconfig, $value, 2, 'def'),
            2, 'def'), $expected,
            "form: Double formatting of $value as $formats[$format][0] - $expected");
    }
}

foreach my $format (0 .. $#formats) {
    %myconfig = ('numberformat' => $formats[$format][0]);
    $LedgerSMB::App_State::User = \%myconfig;
    my $thou = $formats[$format][1];
    my $dec = $formats[$format][2];
    foreach my $rawValue ('10t000d00', '9t999d99', '333d33',
                          '7t777t777d77', '-12d34', '(76t543d21)') {
        $expected = $rawValue;
        $expected =~ s/t/$thou/gx;
        $expected =~ s/d/$dec/gx;
        my $value = $rawValue;
        $value =~ s/t//gx;
        $value =~ s/d/\./gx;
        if ($value =~ m/^\(/gx) {
            $value = Math::BigFloat->new('-'.substr($value, 1, -1));
        } else {
            $value = Math::BigFloat->new($value);
        }
        cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
               "form: $expected parsed as $formats[$format][0] - $value");
    }
    $expected = '12 CR';
    my $value = Math::BigFloat->new('12');
    cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
        "form: $expected parsed as $formats[$format][0] - $value");
    $expected = '21 DR';
    $value = Math::BigFloat->new('-21');
    cmp_ok($form->parse_amount(\%myconfig, $expected), '==',  $value,
        "form: $expected parsed as $formats[$format][0] - $value");

    cmp_ok($form->parse_amount(\%myconfig, ''), '==', 0,
         "form: Empty string returns 0");
}

foreach my $format (0 .. $#formats) {
    %myconfig = ('numberformat' => $formats[$format][0]);
    $LedgerSMB::App_State::User = \%myconfig;
    my $thou = $formats[$format][1];
    my $dec = $formats[$format][2];
    foreach my $rawValue ('10t000d00', '9t999d99', '333d33',
                          '7t777t777d77', '-12d34', '(76t543d21)') {
        $expected = $rawValue;
        $expected =~ s/t/$thou/gx;
        $expected =~ s/d/$dec/gx;
        my $value = $rawValue;
        $value =~ s/t//gx;
        $value =~ s/d/\./gx;
        if ($value =~ m/^\(/gx) {
            $value = Math::BigFloat->new('-'.substr($value, 1, -1));
        } else {
            $value = Math::BigFloat->new($value);
        }
        cmp_ok($form->parse_amount(\%myconfig,
            $form->parse_amount(\%myconfig, $expected)),
            '==',  $value,
            "form: $expected parsed as $formats[$format][0] - $value");
    }
    $expected = '12 CR';
    my $value = Math::BigFloat->new('12');
    cmp_ok($form->parse_amount(\%myconfig,
        $form->parse_amount(\%myconfig, $expected)),
        '==',  $value,
        "form: $expected parsed as $formats[$format][0] - $value");
    $expected = '21 DR';
    $value = Math::BigFloat->new('-21');
    cmp_ok($form->parse_amount(\%myconfig,
        $form->parse_amount(\%myconfig, $expected)),
        '==',  $value,
        "form: $expected parsed as $formats[$format][0] - $value");

    cmp_ok($form->parse_amount(\%myconfig, ''), '==', 0,
        "form: Empty string returns 0");
    cmp_ok($form->parse_amount(\%myconfig), '==', 0,
        "form: undef string returns 0");
}

done_testing;
