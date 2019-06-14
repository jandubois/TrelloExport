use 5.024;
use utf8;
use warnings;

use File::Path qw(make_path);
use File::Spec::Functions qw(catdir catfile);

my $archive = "/tmp/trello";

my $link_dir = catdir($archive, ".links");
make_path($link_dir);

open(my $input, "< :encoding(UTF-8)", $ARGV[0]) or die $!;

sub sanitize {
    $_ = shift;
    s/[^a-zA-Z0-9._-]/ /g;
    s/  +/ /g;
    s/^ +//;
    s/[ ._-]+$//;
    return $_;
}

# perl -nE 'say($1) while /:([a-z_]+):/g' < TrelloExport_20190612180019.md | sort | uniq
my %emoji = (
             angry                 => '😠',
             arrow_down            => '⬇',
             arrow_forward         => '▶',
             arrow_right           => '➡',
             arrow_up              => '⬆',
             arrow_up_down         => '↕',
             ballot_box_with_check => '☑',
             bell                  => '🔔',
             boom                  => '💥',
             brain                 => '🧠',
             cat                   => '🐱',
             cats                  => '🐱',
             chicken               => '🐔',
             confounded            => '😖',
             construction          => '🚧',
             cry                   => '😢',
             dancer                => '💃',
             egg                   => '🥚',
             eyes                  => '👀',
             facepalm              => '🤦',
             fingerscrossed        => '🤞',
             fire                  => '🔥',
             fireworks             => '🎆',
             frowning              => '😦',
             gem                   => '💎',
             green_heart           => '💚',
             grimacing             => '😬',
             gun                   => '🔫',
             headdes               => '🤦',
             headdesk              => '🤦',
             laughing              => '😂',
             ok                    => '🆗',
             poop                  => '💩',
             pray                  => '🙏',
             red_circle            => '🔴',
             rocket                => '🚀',
             sarcasm               => '⸮',
             seat                  => '💺',
             smile                 => '😃',
             smiley_cat            => '😺',
             smiling_imp           => '😈',
             smoking               => '🚬',
             sunny                 => '🌞',
             tea                   => '🍵',
             thumbsdown            => '👎',
             thumbsup              => '👍',
             tophat                => '🎩',
             warning               => '⚠',
             white_check_mark      => '✅',
             x                     => '❌',
            );

my ($board,$list);
my $output;
while (<$input>) {
    chomp;
    s/\A\N{BOM}//;

    if (/^###? / && $output) {
        close($output);
        undef $output;
    }

    if (s/^# //) {
        $board = $_;
        next;
    }

    if (s/^## //) {
        $list = $_;
        next;
    }

    if (s/^### \[(\w{8})\] (\[archived\] )?//) {
        my($id,$archived) = ($1,$2);
        my $card = $_;

        my $dir = catdir($archive, sanitize($board), sanitize($list));
        my $file = catfile($dir, sanitize($card).".md");

        make_path($dir);
        open($output, "> :encoding(UTF-8)", $file) or die;
        symlink($file, catfile($link_dir, $id));

        $card .= " \\[$id\\]";
        $card .= " \\[archived\\]" if $archived;
        say $output "### $card\n";
        say $output "**$list** on **$board**\n";
        next;
    }

    s#:([a-z_]+):#$emoji{$1}//":$1:"#eg;
    s/^(```\S)/ $1/g;

    say $output $_ if defined $output;
}
