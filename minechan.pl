#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(strftime);
use Image::Match;
use Win32::GuiTest qw(:ALL);
use JSON;
use AnyEvent;
use FindBin;
use lib "$FindBin::Bin/lib";
use Mouse;
use Time::HiRes;
use DateTime;

local $| = 1;

#呼叫目標程式
#system "start notepad";
system "start d:\\winmine.exe";
sleep 1;
#檢查目標程式是否存在
my @windows = FindWindowLike(0, "Minesweeper", "");
die "Could not find Paint\n" if not @windows;
#將目標程式設為前景程式
SetForegroundWindow($windows[0]);
sleep 0;

#將滑鼠控制範圍定義在全畫面
#MouseMoveAbsPix((GetWindowRect(GetDesktopWindow()))[0,0]);
MouseMoveAbsPix((GetWindowRect($windows[0]))[0,0]);
#圖片配對初始化
my $base_png = {};
my $big = Image::Match->screenshot;			#需要在計算時重新呼叫一次。
my $z_1 = Prima::Image->load('img\\clone\\z-1.png') or die "Can't load: $@";
my $z_2 = Prima::Image->load('img\\clone\\z-2.png') or die "Can't load: $@";
my $z_3 = Prima::Image->load('img\\clone\\z-3.png') or die "Can't load: $@";
my $z_4 = Prima::Image->load('img\\clone\\z-4.png') or die "Can't load: $@";
my $z_5 = Prima::Image->load('img\\clone\\z-5.png') or die "Can't load: $@";
my $z_6 = Prima::Image->load('img\\clone\\z-6.png') or die "Can't load: $@";
$base_png->{0} = Prima::Image->load('img\\clone\\z0.png') or die "Can't load: $@";
$base_png->{1} = Prima::Image->load('img\\clone\\z1.png') or die "Can't load: $@";
$base_png->{2} = Prima::Image->load('img\\clone\\z2.png') or die "Can't load: $@";
$base_png->{3} = Prima::Image->load('img\\clone\\z3.png') or die "Can't load: $@";
$base_png->{4} = Prima::Image->load('img\\clone\\z4.png') or die "Can't load: $@";
$base_png->{5} = Prima::Image->load('img\\clone\\z5.png') or die "Can't load: $@";
$base_png->{6} = Prima::Image->load('img\\clone\\z6.png') or die "Can't load: $@";
$base_png->{7} = Prima::Image->load('img\\clone\\z7.png') or die "Can't load: $@";
$base_png->{8} = Prima::Image->load('img\\clone\\z8.png') or die "Can't load: $@";

#$base_png->{11} = Prima::Image->load('img\\clone\\z-1.png') or die "Can't load: $@";
#$base_png->{12} = Prima::Image->load('img\\clone\\z-2.png') or die "Can't load: $@";
#$base_png->{13} = Prima::Image->load('img\\clone\\z-3.png') or die "Can't load: $@";
#$base_png->{14} = Prima::Image->load('img\\clone\\z-4.png') or die "Can't load: $@";
$base_png->{15} = Prima::Image->load('img\\clone\\z-5.png') or die "Can't load: $@";
#$base_png->{16} = Prima::Image->load('img\\clone\\z-6.png') or die "Can't load: $@";
$base_png->{98} = Prima::Image->load('img\\clone\\smile_finish.png') or die "Can't load: $@";
$base_png->{99} = Prima::Image->load('img\\clone\\smile_clear.png') or die "Can't load: $@";
$base_png->{100} = Prima::Image->load('img\\clone\\enter_your_name.png') or die "Can't load: $@";

my @base_png_array = qw/0 1 2 3 4 5 6 7 8 15/;
my $route_map = {};
my $checkXY = {};
my $full_map_XY;
my $ref_full_map_XY;
my $ready_map_XY = {};

my $check_over = 0;
my $check_finish = 0;
my $check_name = 0;

&smile_ckeck();

sub smile_ckeck {
#	&dt('=Start time.....');
	# reset storge array and hash.
	my @base_map;
	$route_map = {};
	$checkXY = {};
    $full_map_XY = {};
    $ref_full_map_XY = {};
	
	my $small = Prima::Image->load('img\\smile_start.png') or die "Can't load: $@";
	my ( $x, $y) = $big->match( $small);
	# 13 是因為圖片為26 X 26 取其中心點位置
	$x += 13;
	$y += 13;
	MouseMoveAbsPix($x,$y);
	SendMouse ( "{LEFTCLICK}" );
	my $big = Image::Match->screenshot;

	@base_map = $big->match( $z_1, 'multiple',1);
    #@base_map = $big->match( $base_png->{11}, 'multiple',1);
	
	#初始化地圖
	for (0..($#base_map / 2)) {
			my $yy = pop @base_map;
			my $xx = pop @base_map;
			$$route_map{$yy}{$xx} = -1;
	}
	
	#地圖的虛擬座標與實際座標的轉換紀錄
	my $X = 0;
	for my $keyX ( sort { $a <=> $b } keys %{$route_map} ) {
		my $Y = 0;
		for my $keyY ( sort { $a <=> $b } keys %{$$route_map{$keyX}} ) {
			$full_map_XY->{$X.','.$Y} = {
											XY		=>	$keyX.','.$keyY,
											status	=>	$$route_map{$keyX}{$keyY},
										#	p		=>	5,
										};
			$ref_full_map_XY->{$keyX.','.$keyY} = {
											XY		=>	$X.','.$Y,
											status	=>	$$route_map{$keyX}{$keyY},
										#	p		=>	5,
										};
			$Y++;
		}
		$checkXY->{Y} = $Y;
		$X++;
	}
	$checkXY->{X} = $X;
	&draw_map();
	#MouseMoveAbsPix($x,$y);
	#SendMouse ( "{LEFTCLICK}" );
	&play_time();
	return;
}

#主要程式的運作迴圈
sub play_time {
	&first_rand_click();                #第一次隨機點一下地圖
#	&draw_map();                        #重整一次地圖的座標及機率
#	&gameover();                        #檢查是否踩到地雷，是否需要重置
	while ($check_over <= 0) {          #主要迴圈，等待遊戲結束的訊號
	#	&new_draw_map();
		&draw_map();                    #重整一次地圖的座標及機率
    #    &dt('draw_map....');
		&secend_ai();                   #AI的控制
    #    &dt('secend_ai....');
        &dt('play roll name....');
	}
}

sub first_rand_click {
	my @tmpA = split/\,/,$full_map_XY->{int(rand $checkXY->{X}).','.int(rand $checkXY->{Y})}->{XY};
	MouseMoveAbsPix($tmpA[1],$tmpA[0]);
	print defined($tmpA[1]) ? "first time found at $tmpA[0]:$tmpA[1] $ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{XY}\n" : "not found\n";
	SendMouse ( "{LEFTCLICK}" );
}

#重繪一次地圖，並且將正反向座標及相關紀錄一起紀錄。
sub draw_map {
    my $big = Image::Match->screenshot;
	for (@base_png_array) {
		my $num = $_;
		my @ztmp = $big->match( $base_png->{$num}, 'multiple',1);
		for (0..($#ztmp / 2)) {
			next if !$ztmp[0];
			my $yy = pop @ztmp;
			my $xx = pop @ztmp;
			$$route_map{$yy}{$xx} = $num;
			$ref_full_map_XY->{$yy.','.$xx}->{status} = $num;
			$full_map_XY->{$ref_full_map_XY->{$yy.','.$xx}->{XY}}->{status} = $num;
			&around($yy,$xx) if $num > 0;           #around迴圈是查詢某點四周還未開啟的格子。
		}
	}
	
	#檢查是否爆了或是結束。
	$check_over = &gameover();
	$check_finish = &finish();
	$check_name = &enter_name();
	return if $check_over or $check_finish or $check_name;
	
	my $probability_x = 0;
	for my $keyX ( sort { $a <=> $b } keys %{$route_map} ) {
		my $probability_y = 0;
		for my $keyY ( sort { $a <=> $b } keys %{$$route_map{$keyX}} ) {
		#	print (sprintf "%2d", $$route_map{$keyX}{$keyY});
		#	print "[".$ref_full_map_XY->{$keyX.','.$keyY}->{XY}."]";
			#print "(".$full_map_XY->{$ref_full_map_XY->{$keyX.','.$keyY}->{XY}}->{XY}.")";
			#print "{".$full_map_XY->{$ref_full_map_XY->{$keyX.','.$keyY}->{XY}}->{p}."}";
#			my $pp = $full_map_XY->{$ref_full_map_XY->{$keyX.','.$keyY}->{XY}}->{p};
#			$pp = 0 if !$pp;
#			print "<".(sprintf "%2.2f",$pp).">";
#			print " ";
			$probability_y++;
		}
		$checkXY->{Y} = $probability_y;
#		print "\n";
		$probability_x++;
	}
#	print "\n";
	$checkXY->{X} = $probability_x;
}

sub around {
	my ($i, $j) = @_;
	return unless defined($ref_full_map_XY->{$i.','.$j}->{status} && $ref_full_map_XY->{$i.','.$j}->{status} >= 1);

	my @tmpA = split/\,/,$ref_full_map_XY->{$i.','.$j}->{XY};
	$i = $tmpA[0];
	$j = $tmpA[1];
	my @around = grep {
		defined($full_map_XY->{$_->[0].','.$_->[1]})
	} grep {
		$_->[0] >= 0 && $_->[1] >= 0 &&
		$_->[0] < $checkXY->{Y} &&
		$_->[1] < $checkXY->{X}
	} (
		[$i-1, $j-1], [$i-1, $j], [$i-1, $j+1],
		[$i,   $j-1],             [$i,   $j+1],
		[$i+1, $j-1], [$i+1, $j], [$i+1, $j+1]
	);
	
	my @unknowns = grep { -1 == $full_map_XY->{$_->[0].','.$_->[1]}->{status}	} @around;
	my @mines    = grep { $full_map_XY->{$_->[0].','.$_->[1]}->{status} == 15	} @around;
	
	for (@mines) {
		$full_map_XY->{$_->[0].','.$_->[1]}->{p} = 2;
		$ref_full_map_XY->{$full_map_XY->{$_->[0].','.$_->[1]}->{XY}}->{p} = 2;
	}

	if (@unknowns > 0) {
		my $p = ($full_map_XY->{$i.','.$j}->{status} - (int($#mines)+1)) / (int($#unknowns)+1);
		$ready_map_XY = {};
		for (@unknowns) {
			my $p_xy = $full_map_XY->{$_->[0].','.$_->[1]}->{p};
			if (defined($p_xy)) {
				if ($p == 0 || $p == 1) {
					$full_map_XY->{$_->[0].','.$_->[1]}->{p} = $p;
				}
			}
			else {
				$full_map_XY->{$_->[0].','.$_->[1]}->{p} = $p;
			}
		#	print STDERR Dumper __FILE__." ".__LINE__,$full_map_XY->{$_->[0].','.$_->[1]}->{p};
		#	print (sprintf "%2.2f",$full_map_XY->{$_->[0].','.$_->[1]}->{p});
		#	print "[".$ref_full_map_XY->{$full_map_XY->{$_->[0].','.$_->[1]}->{XY}}->{XY}."] \n";
			
			if ($full_map_XY->{$_->[0].','.$_->[1]}->{p} == 1 && $full_map_XY->{$_->[0].','.$_->[1]}->{status} != 15) {
				my @tmpB = split/\,/,$full_map_XY->{$_->[0].','.$_->[1]}->{XY};
				&mouse_right_click($tmpB[0],$tmpB[1]);
			}
			
			# new.......................
			if (defined($full_map_XY->{$_->[0].','.$_->[1]}->{p}) && ($full_map_XY->{$_->[0].','.$_->[1]}->{p} < 1) && ($full_map_XY->{$_->[0].','.$_->[1]}->{status} < 0 )) {
				push @{$ready_map_XY->{$full_map_XY->{$_->[0].','.$_->[1]}->{p}}} , $full_map_XY->{$_->[0].','.$_->[1]}->{XY};
			}
		}
#		print STDERR Dumper __FILE__." ".__LINE__,$ready_map_XY;
		for my $key ( sort { $a<=>$b } keys %{$ready_map_XY} ) {

			if ($key == 0) {
				my @tmp = @{$ready_map_XY->{$key}};
				#print Dumper @tmp;
				my $XY = int(rand($#tmp - 1));
				my @tmpA = split/\,/,$tmp[$XY];
				if ($ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{status} < 0 && !$ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{p}) {
					#print STDERR Dumper __FILE__." ".__LINE__,$ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{status};
					&mouse_left_click($tmpA[0],$tmpA[1]);
					last;
				}
			} else {
				last;
			}
		}
			
	}
#sleep 3;
}

sub secend_ai {
#	print STDERR Dumper __FILE__." ".__LINE__,$ready_map_XY;
	for my $key ( sort { $a<=>$b } keys %{$ready_map_XY} ) {
		if (defined($ready_map_XY->{$key})) {
			my @tmp = @{$ready_map_XY->{$key}};
			#print Dumper @tmp;
			my $XY = int(rand($#tmp - 1));
			my @tmpA = split/\,/,$tmp[$XY];
			if ($ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{status} < 0 && !$ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{p}) {
                #print STDERR Dumper __FILE__." ".__LINE__,$ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{status};
				&mouse_left_click($tmpA[0],$tmpA[1]);
				last;
			}
		}
	}
}

sub draw_draw_map {
	&dt('draw draw map ....');
    my $big = Image::Match->screenshot;
	for (@base_png_array) {
		my $num = $_;
		my @ztmp = $big->match( $base_png->{$num}, 'multiple',1);
		for (0..($#ztmp / 2)) {
			next if !$ztmp[0];
			my $yy = pop @ztmp;
			my $xx = pop @ztmp;
			$$route_map{$yy}{$xx} = $num;
			$ref_full_map_XY->{$yy.','.$xx}->{status} = $num;
			$full_map_XY->{$ref_full_map_XY->{$yy.','.$xx}->{XY}}->{status} = $num;
			#&around($yy,$xx) if $num > 0;           #around迴圈是查詢某點四周還未開啟的格子。
		}
	}
	#檢查是否爆了或是結束。
	$check_over = &gameover();
	$check_finish = &finish();
	$check_name = &enter_name();
	return if $check_over or $check_finish or $check_name;
}

sub mouse_left_click {
	my $X = shift;
	my $Y = shift;
	MouseMoveAbsPix($Y,$X);
	#print defined($X) ? "LEFT time found at $X:$Y\n" : "not found\n";
	
#	&dt('Mouse LEFT click at '.$ref_full_map_XY->{$X.','.$Y}->{XY}.' ....');
	SendMouse ( "{LEFTCLICK}" );
	$ref_full_map_XY->{$X.','.$Y}->{status} = 2;
	$full_map_XY->{$ref_full_map_XY->{$X.','.$Y}->{XY}}->{status} = 2;
#	$ref_full_map_XY->{$X.','.$Y}->{p} = 0;
#	$full_map_XY->{$ref_full_map_XY->{$X.','.$Y}->{XY}}->{p} = 0;
#	&around($Y,$X);
	&draw_draw_map();				#再畫一次，可以增加判斷的精準度，但~~速度就變慢很多了~~  Orz...  二難...
#	&mouse_LR_click($X,$Y);
	return;
}

sub mouse_right_click {
	my $X = shift;
	my $Y = shift;
	MouseMoveAbsPix($Y,$X);
	#print defined($X) ? "RIGHT time found at $X:$Y\n" : "not found\n";
#	&dt('=Mouse RIGHT click at '.$X.':'.$Y.'....');
	SendMouse ( "{RIGHTCLICK}" );
	$ref_full_map_XY->{$X.','.$Y}->{status} = 15;
	$full_map_XY->{$ref_full_map_XY->{$X.','.$Y}->{XY}}->{status} = 15;
	#&mouse_LR_click($X,$Y);
	return;
}

sub mouse_LR_click {
	my $X = shift;
	my $Y = shift;
	my $roll1 = int(rand(1));
	MouseMoveAbsPix($Y,$X);
	SendMouse ( "{LEFTDOWN}" );
	SendMouse ( "{RIGHTDOWN}" );
	SendMouse ( "{RIGHTUP}" );
	SendMouse ( "{LEFTUP}" );
	return;
}

sub reset {
	$full_map_XY = {};
    $ref_full_map_XY = {};
	&smile_ckeck();
	SendMouse ( "{LEFTCLICK}" );
	print "reset game!! \n";
	return;
}

sub gameover {
	my $big = Image::Match->screenshot;
	my ( $x, $y) = $big->match( $z_3);
	if ($x && $y) {
	#	my $p = $ref_full_map_XY->{$x.','.$y}->{p};
	#	print STDERR Dumper __FILE__." ".__LINE__,$ref_full_map_XY->{$y.','.$x}->{XY},$p;
		print "BOMB in $x , $y P =  Game Over!! \n";
		#sleep 2;
		&reset();
		#return 1;
	} else {
		return 0;
	}
	
}

sub finish {
	my $big = Image::Match->screenshot;
	my ( $x, $y) = $big->match( $base_png->{98} );
	if ($x && $y) {
		print "bot finish!! \n";
		#&dt('=Finish time.....');
		sleep 2;
		&reset();
		#return 1;
	} else {
		return 0;
	}
}

sub enter_name {
	my $big = Image::Match->screenshot;
	my ( $x, $y) = $big->match( $base_png->{100} );
	if ($x && $y) {
		MouseMoveAbsPix($x,$y);
		SendMouse ( "{LEFTCLICK}" );
		SendKeys("sea mine bot. YA...");
		PushButton("OK");
		PushButton("OK");
		SendKeys("{ENTER}");
		print strftime("%H:%M:%S.%5N")." enter name finish!! \n";
		sleep 2;
		&reset();
		#return 1;
	} else {
		return 0;
	}
}

sub dt {
	my $txt = shift;
	my $dt = DateTime->from_epoch(	epoch	=> Time::HiRes::time , time_zone => 'local', );
	print "$txt ---SEC--- ",$dt->strftime("%H:%M:%S.%5N")," === time ===\n";
}

#新的地圖構成方式。
sub new_draw_map {

#	[-1, -1], [-1, 0], [-1, +1]
#	[0,  -1],          [0,  +1]
#	[+1, -1], [+1, 0], [+1, +1]
	
	for (@base_png_array) {
		my $num = $_;
		my $big = Image::Match->screenshot;
		my @ztmp = $big->match( $base_png->{$num}, 'multiple',1);
		for (0..($#ztmp / 2)) {
			next if !$ztmp[0];
			my $yy = pop @ztmp;
			my $xx = pop @ztmp;
			
			$$route_map{$yy}{$xx} = $num;
			$ref_full_map_XY->{$yy.','.$xx}->{status} = $num;
			$full_map_XY->{$ref_full_map_XY->{$yy.','.$xx}->{XY}}->{status} = $num;
			
			#&around($yy,$xx) if $num > 0;
			
			my @tmpA = split/\,/,$ref_full_map_XY->{$yy.','.$xx}->{XY};
			my $X = $tmpA[0];
			my $Y = $tmpA[1];

			$full_map_XY->{($X-1).','.($Y-1)}->{probability}	+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X-1).','.($Y-1)})) && ($full_map_XY->{($X-1).','.($Y-1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$full_map_XY->{($X-1).','.($Y)}->{probability}		+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X-1).','.($Y)})) && ($full_map_XY->{($X-1).','.($Y)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$full_map_XY->{($X-1).','.($Y+1)}->{probability}	+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X-1).','.($Y+1)})) && ($full_map_XY->{($X-1).','.($Y+1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			
			$full_map_XY->{($X).','.($Y-1)}->{probability}		+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X).','.($Y-1)})) && ($full_map_XY->{($X).','.($Y-1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$full_map_XY->{($X).','.($Y+1)}->{probability}		+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X).','.($Y+1)})) && ($full_map_XY->{($X).','.($Y+1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			
			$full_map_XY->{($X+1).','.($Y-1)}->{probability}	+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X+1).','.($Y-1)})) && ($full_map_XY->{($X+1).','.($Y-1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$full_map_XY->{($X+1).','.($Y)}->{probability}		+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X+1).','.($Y)})) && ($full_map_XY->{($X+1).','.($Y)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$full_map_XY->{($X+1).','.($Y+1)}->{probability}	+= $full_map_XY->{$X.','.$Y}->{status} if (defined($full_map_XY->{($X+1).','.($Y+1)})) && ($full_map_XY->{($X+1).','.($Y+1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			
			$ref_full_map_XY->{$full_map_XY->{($X-1).','.($Y-1)}->{XY}}->{probability} 	= $full_map_XY->{($X-1).','.($Y-1)}->{probability}	if (defined($full_map_XY->{($X-1).','.($Y-1)})) && ($full_map_XY->{($X-1).','.($Y-1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$ref_full_map_XY->{$full_map_XY->{($X-1).','.($Y)}->{XY}}->{probability}	= $full_map_XY->{($X-1).','.($Y)}->{probability}	if (defined($full_map_XY->{($X-1).','.($Y)})) && ($full_map_XY->{($X-1).','.($Y)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$ref_full_map_XY->{$full_map_XY->{($X-1).','.($Y+1)}->{XY}}->{probability}	= $full_map_XY->{($X-1).','.($Y+1)}->{probability}	if (defined($full_map_XY->{($X-1).','.($Y+1)})) && ($full_map_XY->{($X-1).','.($Y+1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			
			$ref_full_map_XY->{$full_map_XY->{($X).','.($Y-1)}->{XY}}->{probability}	= $full_map_XY->{($X).','.($Y-1)}->{probability}	if (defined($full_map_XY->{($X).','.($Y-1)})) && ($full_map_XY->{($X).','.($Y-1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$ref_full_map_XY->{$full_map_XY->{($X).','.($Y+1)}->{XY}}->{probability}	= $full_map_XY->{($X).','.($Y+1)}->{probability}	if (defined($full_map_XY->{($X).','.($Y+1)})) && ($full_map_XY->{($X).','.($Y+1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			
			$ref_full_map_XY->{$full_map_XY->{($X+1).','.($Y-1)}->{XY}}->{probability}	= $full_map_XY->{($X+1).','.($Y-1)}->{probability}	if (defined($full_map_XY->{($X+1).','.($Y-1)})) && ($full_map_XY->{($X+1).','.($Y-1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$ref_full_map_XY->{$full_map_XY->{($X+1).','.($Y)}->{XY}}->{probability}	= $full_map_XY->{($X+1).','.($Y)}->{probability}	if (defined($full_map_XY->{($X+1).','.($Y)})) && ($full_map_XY->{($X+1).','.($Y)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
			$ref_full_map_XY->{$full_map_XY->{($X+1).','.($Y+1)}->{XY}}->{probability}	= $full_map_XY->{($X+1).','.($Y+1)}->{probability}	if (defined($full_map_XY->{($X+1).','.($Y+1)})) && ($full_map_XY->{($X+1).','.($Y+1)}->{status} < 0) && $full_map_XY->{$X.','.$Y}->{status} != 15;
		}
	}
# new_draw_map_start ---SEC--- 16:45:47.11648 === time ===
# new_draw_map_end ---SEC--- 16:45:47.35984 === time ===
#print Dumper $full_map_XY;
#print Dumper $ref_full_map_XY;
	&stupid_ai();
	&draw_map();
}

sub stupid_ai {
	my $ready_map_XY = {};
	for my $X (0..($checkXY->{X} -1)) {
		for my $Y (0..($checkXY->{Y} -1)) {
			if (defined($full_map_XY->{$X.','.$Y}->{probability}) && ($full_map_XY->{$X.','.$Y}->{probability} < 14) && ($full_map_XY->{$X.','.$Y}->{status} < 0)) {
				#print STDERR Dumper $full_map_XY->{$X.','.$Y}->{XY}.' '.$full_map_XY->{$X.','.$Y}->{probability};
			#	push @{$ready_map_XY->{$full_map_XY->{$X.','.$Y}->{p}}} , $full_map_XY->{$X.','.$Y}->{XY};
				push @{$ready_map_XY->{$full_map_XY->{$X.','.$Y}->{probability}}} , $full_map_XY->{$X.','.$Y}->{XY};
			}
			delete $full_map_XY->{$X.','.$Y}->{probability};
			delete $ref_full_map_XY->{$X.','.$Y}->{probability};
		}
	}
	#print Dumper $ready_map_XY;
	for my $key ( sort { $a<=>$b } keys %{$ready_map_XY} ) {
		if (defined($ready_map_XY->{$key})) {
			my @tmp = @{$ready_map_XY->{$key}};
			my $XY = int(rand($#tmp - 1));
			my @tmpA = split/\,/,$tmp[$XY];
			#print STDERR Dumper __FILE__.' '.__LINE__,$ref_full_map_XY->{$tmpA[0].','.$tmpA[1]}->{probability},$key,$#tmp,$XY,$tmpA[0],$tmpA[1];
			&mouse_left_click($tmpA[0],$tmpA[1]);
			last;
		}
	}
}

__DATA__
#定義滑鼠控制在目標程式內
#MouseMoveAbsPix((GetWindowRect($windows[0]))[0,1]);
#SendMouse ( "{REL20,5}" );
#SendMouse ( "{LEFTCLICK}" );
#SendMouse ( "{LEFTDOWN}" );
#SendMouse ( "{LEFTUP}" );

#圖片配對的初始化及存檔及比對的範例
#   my $big = Image::Match->screenshot;
#	#my $small = $big-> extract( 230, $big-> height - 70 - 230, 70, 70);
#	my $small = $big-> extract( 230, $big-> height - 70 - 5, 70, 70);
#	$small-> save('1.png');
#	$small = Prima::Image-> load('1.png') or die "Can't load: $@";
#	my ( $x, $y) = $big-> match( $small);
#	print defined($x) ? "found at $x:$y\n" : "not found\n";

#參考程式(癈)
#	MouseMoveAbsPix((GetWindowRect($windows[0]))[0,1]);
#	SendMouse ( "{REL0,0}" );
#	sleep 1;
#	my ($cx, $cy) = GetCursorPos();
#	my $sx = 0 - $cx;
#	my $sy = 0 - $cy;
#	my $zx = $x - $cx;# * 2 - 2;
#	my $zy = $y - $cy;# - 11;
#	my $mx = $cx+$zx;
#	my $my = $cy+$zy;
	
#	print defined($cx) ? "found at cxy = $cx:$cy  zxy = $zx:$zy mxy $mx:$my \n" : "not found\n";
#	SendMouse ( "{REL$sx,$sy}" );
#	sleep 1;
    
	#SendMouse ( "{REL$zx,$zy}" );
#	MouseMoveAbsPix($zx,$zy);
#	sleep 1;
#	($cx, $cy) = GetCursorPos();
#	print defined($cx) ? "found at cxy = $cx:$cy  zxy = $zx:$zy \n" : "not found\n";
#	sleep 1;
	
#	$x = int(($x - $cx)/2) + 8;
#	$y = $y - $cy + 2;
#	print defined($x) ? "found at $x:$y\n" : "not found\n";
#	SendMouse ( "{REL$x,$y}" );
#	SendMouse ( "{LEFTCLICK}" );
	#開始挑一個地方開工
	
#    sleep 1;
#    ($cx, $cy) = GetCursorPos();
#    $zx = 0 - $cx;
#    $zy = 0 - $cy;
#    print defined($zx) ? "found at $zx:$zy\n" : "not found\n";
#    SendMouse ( "{REL$zx,$zy}" );
#    sleep 1;
#    print defined($x) ? "found at $x:$y\n" : "not found\n";
#	SendMouse ( "{REL$x,$y}" );
#	SendMouse ( "{LEFTCLICK}" );



#		PushButton("Yes");
#		PushButton("&Save");
#		PushButton("&Guardar");
#		PushButton("^Cancel");
#		SendKeys("{ESC}");



__DATA__

#system "start notepad";
system "start d:\\winmine.exe";
sleep 1;

my @windows = FindWindowLike(0, "Minesweeper", "");
die "Could not find Paint\n" if not @windows;

my $menu = GetMenu(GetForegroundWindow());
print "Menu: $menu\n";
my $submenu = GetSubMenu($menu, 0);
print "Submenu: $submenu\n";
print "Count:", GetMenuItemCount($menu), "\n";

my %h = GetMenuItemInfo($menu, 1);   # Edit on the main menu
print Dumper \%h;
%h = GetMenuItemInfo($submenu, 1);   # Open in the File menu
print Dumper \%h;
%h = GetMenuItemInfo($submenu, 4);   # Separator in the File menu
print Dumper \%h;

print "===================\n";
menu_parse($menu);

#MenuSelect("&Archivo|&Salir");

# Close the menu and notepad
SendKeys("{ESC}%{F4}");	# Alt-F4 to exit


# this function receives a menu id and prints as much information about that menu and 
# all its submenues as it can
# One day we might include this in the distributionor in some helper module
sub menu_parse {
	my ($menu, $depth) = @_;
	$depth ||= 0;
	
	foreach my $i (0..GetMenuItemCount($menu)-1) {
			my %h = GetMenuItemInfo($menu, $i);
			print "   " x $depth;
			print "$i  ";
			print $h{text} if $h{type} and $h{type} eq "string"; 
			print "------" if $h{type} and $h{type} eq "separator"; 
			print "UNKNOWN" if not $h{type};
			print "\n";
			
			my $submenu = GetSubMenu($menu, $i);
			if ($submenu) {
					menu_parse($submenu, $depth+1);
			}
	}
}


SendKeys("%{F4}");	# Alt-F4 to exit



__DATA__

    if ($ARGV[0] eq "mouse") {
       my ($left, $top, $right, $bottom) = GetWindowRect($windows[0]);
       # find the appropriate child window and click on  it
       my @children = GetChildWindows($windows[0]);
       foreach my $title (qw(7 * 5 =)) {
           my ($c) = grep {$title eq GetWindowText($_)} @children;
           my ($left, $top, $right, $bottom) = GetWindowRect($c);
           MouseMoveAbsPix(($right+$left)/2,($top+$bottom)/2);
           SendMouse("{LeftClick}");
           sleep(1);
       }
       printf "Result: %s\n", WMGetText($children[0]);
       
       MouseMoveAbsPix($right-10,$top+10);  # this probably depends on the resolution
       sleep(2);
       SendMouse("{LeftClick}");
    }