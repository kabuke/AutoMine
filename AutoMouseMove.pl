use strict;
use warnings;
use utf8;

use Win32::GuiTest qw(:ALL);
use Time::HiRes qw(sleep);

UnicodeSemantics(1);

# デスクトップウィンドウの取得
my $desktop_win = GetDesktopWindow();

# デスクトップウィンドウの矩形の取得
my ($left, $top, $right, $bottom) = GetWindowRect($desktop_win);

# (left, top は 0 だよねーっと）一応確認
die "Oops!" if $left != 0 || $top != 0;

for (my $i = 0; $i < 500; $i++) {
    sleep(0.01);

    # デスクトップ全体をマウスが回る（この爽快感！）
    MouseMoveAbsPix(
        cos($i / 10) * $right / 2 + $right / 2,
        sin($i / 10) * $bottom / 2  + $bottom / 2
    );
}