include <fasteners.scad>
include <bearings.scad>
include <NEMA17.scad>
include <cog.scad>
include <Triangles.scad>

// [w, l, t] = [y, x, z]
$fn = 48;

render_part(5);

module render_part(part_to_render) {
	if (part_to_render == 1) end_motor();

	if (part_to_render == 2) end_idler();

	if (part_to_render == 3) carriage();

	if (part_to_render == 4) effector();

	if (part_to_render == 5) bed_adapter();

	if (part_to_render == 10) assembly();

}

// printer dims
r_printer = 172; // radius of the printer
cc_guides = 60; // center-to-center of the guide rods
d_guides = 8.5; // diameter of the guide rods

// belt, pulley and idler dims
od_idler = od_608; // idler OD
id_idler = id_608; // idler id
h_idler = h_608; // thickness of idler
h_idler_washer = h_M8_washer; // idelr bearing washer
w_belt = 6; // width of the belt (not used)
d_pulley = 16.9; // diameter of the pulley (used to center idler)

// guide rod dims
pad_clamp = 6; // additional material around guide rods
gap_clamp = 2; // opening for clamp

// the radius of the delta measured from the center of the guide rods to the center of the triangle
// as drawn here, the tangent is parallel to the x-axis and the guide rod centers lie on y=0
cc_mount = 75; // tangential distance from center of guide rods to side mount pivot point
w_mount = 12; // thickness of the tabs the boards making up the triangle sides will attach to
l_mount = 30; // length of said tabs

// various radii and chord lengths
a_arc_guides = asin(cc_guides / 2 / r_printer); // angle of arc between guide rods at r_printer 
a_sep_guides = 120 - 2 * a_arc_guides; // angle of arc between nearest rods on neighboring towers
l_chord_guides = 2 * r_printer * sin(a_sep_guides / 2); // length of chord between nearest rods on neighboring towers
r_tower_center = pow(pow(r_printer, 2) - pow(cc_guides / 2, 2), 0.5); // radius to centerline of tower
r_mount_pivot = pow(pow(r_tower_center, 2) + pow(cc_mount / 2, 2), 0.5); // radius to pivot point of apex mounts
a_arc_mount = asin(cc_mount / 2 / r_mount_pivot);// angle subtended by arc struck between tower centerline and mount pivot point
a_sep_mounts = 120 - 2 * a_arc_mount; // angle subtended by arc struck between mount pivot points between adjacent towers
l_chord_pivots = 2 * r_mount_pivot * sin(a_sep_mounts / 2); // chord length between adjacent moint pivot points

// remove enough material from mount so that a logical length board can be cut to ensure adjacent mount pivot point chord lengths will yield a printer having r_printer
l_brd = floor(l_chord_pivots / 10) * 10 - l_mount / 2; // length of the board that will be mounted between the apexs to yield r_printer
l_pad_mount = (l_chord_pivots - l_brd) / 2;

l_idler_relief = cc_guides - d_guides - pad_clamp;
w_idler_relief = 2 * (h_idler + h_idler_washer) + 1;
r_idler_relief = 2; // radius of the relief inside the apex
l_clamp = cc_guides + d_guides + pad_clamp;
w_clamp = w_idler_relief + pad_clamp;
t_clamp = od_idler + 6;

// ball joint mount dimensions
l_ball_joint = 7 + 2 * h_M3_washer;
d_ball_joint = 6;
d_mount_ball_joint = d_ball_joint + 4;
l_mount_ball_joint = l_ball_joint + 6;

// effector dims
l_add_effector = 25;
l_effector = cc_guides + l_mount_ball_joint + l_add_effector;
H_effector = equilateral_height_from_base(l_effector);
r_effector_sides = l_effector * tan(30) / 2;
t_effector = 6;

// carriage dims:
w_carriage_web = 4;
t_carriage = l_lm8uu + 4;

l_guide_rods = 300; // length of the guide rods - only used for assembly

echo(str("Distance between nearest neighbor guide rods = ", l_chord_guides, "mm"));
echo(str("Radius to centerline of tower = ", r_tower_center, "mm"));
echo(str("Radius to mount tab pivot = ", r_mount_pivot, "mm"));
echo(str("Distance between adjacent mount pivot points = ", l_chord_pivots, "mm"));
echo(str("Length of board to yield printer radius of ", r_printer, "mm  = ", l_brd, "mm"));
echo(str("Effector offset = ", r_effector_sides, "mm"));
echo(str("Carriage offset = ", d_mount_ball_joint + od_lm8uu / 2, "mm"));
echo(str("Linking board tab thickness = ", t_clamp, "mm"));
echo(str("Linking board hole c-c = ", t_clamp / 2, "mm"));

module template() {
	color([1, 0, 0])
		difference() {
			circle(r = (r_tower_center + w_clamp / 2) / cos(30), $fn = 6);

			circle(r = (r_tower_center - w_clamp / 2) / cos(30), $fn = 6);

			for(i = [0:2])
				rotate([0, 0, 120 * i])
					for (j = [-1, 1])
						translate([j * cc_guides / 2, r_tower_center, 0])
							circle(r = d_guides / 2);

		}
}

module mount() {
	difference() {
		hull() {
			cylinder(r = w_mount / 2, h = t_clamp, center = true);

			translate([0, -l_mount + w_mount / 2, 0])
				cube([w_mount, w_mount, t_clamp], center = true);
		}

		// relief for board between apexs
		translate([w_mount - 3, -l_mount / 2 - l_pad_mount, 0])
			cube([w_mount, l_mount, t_clamp + 2], center = true);

		// screw holes to mount board
		for (i = [-1, 1])
			translate([0, -l_mount + 10, i * t_clamp / 4])
				rotate([0, 90, 0])
					union() {
					cylinder(r = d_M3_screw / 2, h = w_mount + 2, center = true);

					translate([0, 0, -w_mount / 2])
						cylinder(r = d_M3_nut / 2, h = 2 * h_M3_nut, $fn = 6, center = true);
					
				}
	}
}

module apex() {
	hull() {
		for (i=[-1,1])
			translate([i * (cc_mount - w_mount) / 2, 0, 0])
				cylinder(r = w_mount / 2, h = t_clamp, center = true);
	}

	for (i = [-1, 1])
		translate([i * cc_mount / 2, 0, 0])
			rotate([0, 0, i * 30])
				mirror([(i < 0) ? i : 0, 0, 0])
					mount();
}

module round_box(
	length,
	width,
	thickness,
	radius = 4) {
	hull() {
		for (i = [-1, 1]) {
			translate([i * (length / 2 - radius), width / 2 - radius, 0])
				cylinder(r = radius, h = thickness, center = true);

			translate([i * (length / 2 - radius), -(width / 2 - radius), 0])
				cylinder(r = radius, h = thickness, center = true);
		}
	}
}

module rod_clamp_relief(thickness) {
	union() {
		// clamp screws
		for (i = [-1, 1])
			translate([0, (w_clamp - d_guides) / 2, i * t_clamp / 4 - (thickness - t_clamp) / 2])
				rotate([0, 90, 0]) {
					translate([0, 0, (l_clamp / 2 + 4.5)])
						cylinder(r = d_M3_cap / 2 + 1, h = 10, center = true);

					translate([0, 0, -(l_clamp / 2 + 4.5)])
						cylinder(r = d_M3_cap / 2 + 1, h = 10, center = true);

					difference() {
						union() {
							cylinder(r = d_M3_screw / 2, h = l_clamp + 2, center = true);

							cylinder(r = d_M3_nut / 2, h = l_idler_relief + 2 * h_M3_nut, center = true, $fn = 6);
						}

						cylinder(r = d_M3_nut / 2 + 1, h = l_idler_relief - 2 * h_M3_nut, center = true);
					}
				}

		// guide rod holes and slots for clamp
		for (i = [-1, 1])
			translate([i * cc_guides / 2, 0, 0]) {
				cylinder(r = d_guides / 2, h = thickness, center = true);

				translate([0, w_clamp / 2, 0])
					cube([gap_clamp, w_clamp, thickness], center = true);
			}
	}
}

module end_idler() {
	difference() {
		union() {
			round_box(
				l_clamp,
				w_clamp,
				t_clamp);

			apex();
		}

		// place the idler shaft such that the belt is parallel with the pulley - the belt dog will be on the right looking down the vertical axis
		translate([(d_pulley - od_idler) / 2, 0, 0])
			rotate([90, 0, 0])
				cylinder(r = id_idler / 2, h = w_clamp + 2, center = true);

		// idler will be two bearing thick plus two washers
		round_box(
			length = l_idler_relief,
			width = w_idler_relief,
			thickness = t_clamp + 2,
			radius = r_idler_relief);

		rod_clamp_relief(thickness = t_clamp + 2);

		// limit switch mount
			translate([-l_clamp / 2 + 12, -w_clamp / 2, t_clamp / 2 - 6])
				rotate([90, 0, 0]) {
					translate([9.5 / 2, 0, 0])
							cylinder(r = 1, h = 12, center = true);

					translate([-9.5 / 2, 0, 0])
							cylinder(r = 1, h = 12, center = true);
				}
	}
}

module end_motor() {
	difference() {
		union() {
			apex();

			translate([0, 0, (l_NEMA17 - t_clamp) / 2])
			round_box(
					l_clamp,
					w_clamp,
					l_NEMA17);
		}

		translate([0, 0, (l_NEMA17 - t_clamp) / 2]) {
			round_box(
				length = l_idler_relief,
				width = w_idler_relief,
				thickness = l_NEMA17 + 2,
				radius = r_idler_relief);

			rod_clamp_relief(thickness = l_NEMA17 + 2);
		}

		// motor mount
		translate([0, w_clamp / 2 + 1, (l_NEMA17 - t_clamp) / 2])
			rotate([90, 0, 0])
				NEMA17_parallel_holes(
					w_clamp + 2,
					0);

		// limit switch mount
		translate([(l_clamp / 2 - 9), -w_clamp / 2, t_clamp - 6])
			rotate([90, 0, 0]) {
				translate([9.5 / 2, 0, 0])
						cylinder(r = 1, h = 12, center = true);

				translate([-9.5 / 2, 0, 0])
						cylinder(r = 1, h = 12, center = true);
			}
	}
}

module carriage() {
	y_web = -w_carriage_web / 2 - id_lm8uu / 2;
	difference() {
		union() {
			// bearing saddles
			for (i = [-1, 1])
				translate([i * cc_guides / 2, 0, 0]) {
					cylinder(r = od_lm8uu / 2 + 3, h = t_carriage, center = true);

					// ball joint mounts
					translate([0, -od_lm8uu / 2, -(l_lm8uu - 4) / 2 + 1])
						rotate([0, 90, 0])
							mirror([0, 0, (i == 1) ? 1 : 0])
								ball_mount();
				}

			// web
			translate([0, y_web, 0])
				cube([cc_guides, w_carriage_web, t_carriage], center = true);

			// spring mount
			translate([0, -od_lm8uu / 3 + y_web - 1, 0])
				rotate([90, 0, 0])
					rotate([0, 0, 90])
						spring_mount();
			// end stop
			translate([-cc_guides / 2, -od_lm8uu / 2 - 3, t_carriage / 2 - 2.75 * 1.5 * h_M3_nut])
				scale([1, 1.6, 1])
					union() {
						cylinder(r1 = 0, r2 = d_M3_screw + 1.5, h = 2.75 * h_M3_nut, center = true);

						translate([0, 0, 2.75 * h_M3_nut])
							cylinder(r =  d_M3_screw + 1.5, h = 2.75 * h_M3_nut, center = true);
					}
		}

		for (i = [-1, 1])
			translate([i * cc_guides / 2, 0, 0]) {
				for (j = [0, 1])
					translate([0, j * (od_lm8uu / 2 - 1), 0])
						cylinder(r = od_lm8uu / 2, h = l_lm8uu, center = true);

				hull() {
					cylinder(r = d_guides / 2, h = t_carriage + 2, center = true);

					translate([0, od_lm8uu / 2 + 3, 0])
						cylinder(r = d_guides / 2, h = t_carriage + 2, center = true);
				}

				translate([0, 10, 0])
					cube([od_lm8uu + 8, od_lm8uu / 2 + 5, t_carriage + 4], center = true);

				// slot for wire tie
				translate([0, 0, 4])
					difference() {
						hull() {
							cylinder(r = od_lm8uu / 2 + 2, h = 4, center = true);

							translate([0, -20, 0])
								cylinder(r = od_lm8uu / 2 + 2, h = 4, center = true);
						}

						hull() {
							cylinder(r = od_lm8uu / 2 + 1, h = 6, center = true);

							translate([0, -20, 0])
								cylinder(r = od_lm8uu / 2 + 1, h = 6, center = true);
						}
					}
			}

		// end stop
		translate([-cc_guides / 2, -od_lm8uu / 2 - 3 - 5, t_carriage / 2 - h_M3_nut])
			cylinder(r = d_M3_screw / 2 - 0.3, h = 20, center = true);


		// mount for belt terminator
		translate([-d_pulley / 2, y_web, -t_carriage / 2 + d_M3_screw / 2 + 5])
			rotate([90, 0, 0]) {
				cylinder(r = d_M3_screw / 2, h = w_carriage_web + 2, center = true);

				translate([0, 0, w_carriage_web / 2])
					cylinder(r = d_M3_nut / 2, h = h_M3_nut, center = true, $fn = 6);
			}
	}

	// floor for rod opening
	for (i = [-1, 1])
		translate([i * cc_guides / 2, -0.35, (l_lm8uu + 0.25) / 2])
			cube([od_lm8uu, id_lm8uu, 0.25], center = true);}

module ball_mount() {
	difference() {
			union() {
				hull() {
						cylinder(r = d_mount_ball_joint / 2, h = l_mount_ball_joint, center = true);

					translate([0, -d_mount_ball_joint, 0])
						cylinder(r = d_mount_ball_joint / 2, h = l_mount_ball_joint, center = true);
				}

				translate([-d_mount_ball_joint / 2, 0, 0])
					cylinder(r = d_mount_ball_joint, h = l_mount_ball_joint, center = true);
			}

			translate([0, -d_mount_ball_joint, 0]) {
				cylinder(r = d_M3_screw / 2, h = l_mount_ball_joint + 2, center = true);

				translate([0, 0, (l_ball_joint + 6) / 2])
					cylinder(r = d_M3_nut / 2, h = h_M3_nut, $fn = 6, center = true);

				translate([-1.5 * d_mount_ball_joint, 0, 0])
					cylinder(r = d_mount_ball_joint, h = l_mount_ball_joint + 2, center = true);
			}

			translate([0, -7, 0])
				rotate([0, 90, 0])
						hull() {
						cylinder(r = l_ball_joint / 2, h = d_mount_ball_joint * 2, center = true);

						translate([0, -20, 0])
							cylinder(r = l_ball_joint / 2, h = d_mount_ball_joint * 2, center = true);
					}

	}
}

module spring_mount() {
	thickness = 15.0;
	d_gap = thickness - 5;
	rotate([270, 0, 0])
	difference() {
		hull() {
			cylinder(r = d_M3_screw / 2 + 2, h = thickness, center = true);

			translate([0, 5, 0])
				cube([d_M3_screw + 8, 2, thickness], center = true);
		}

		cylinder(r = d_M3_screw / 2, h = thickness + 2, center = true);

		rotate([0, 90, 0])
			hull()
				for (i = [-1, 1])
					translate([0, i * 5 - 4, 0])
						cylinder(r = d_gap / 2, h = 20, center = true);
	}
}

module effector() {
	b_effector = equilateral_base_from_height(H_effector);
	r_effector = b_effector / 2 / sin(60);
	difference() {
		union() {
			
//			translate([0, r_effector_sides - H_effector, 0])
//				linear_extrude(height  = t_effector)
//					equilateral(H_effector);
			
			hull()
				for (i = [0:2])
					rotate([0, 0, i * 120])
						translate([0, -r_effector, 0])
							cylinder(r = 4, h = t_effector);


			for (i = [0:2])
				rotate([0, 0, i * 120 - 30])
					translate([r_effector_sides, 0, t_effector]) {
						translate([0, -cc_guides / 2, 0])
							rotate([-90, 0, 0])
								ball_mount();

						translate([0, cc_guides / 2, 0])
							rotate([-90, 0, 0])
								mirror([0, 0, 1])
									ball_mount();

						translate([-5.5, 0, t_effector])
							scale([0.95, 0.95, 1])
								spring_mount();
					}
		}

		// flat bottom
		translate([0, 0, -10])
			cylinder(r = H_effector, h = 10);

		// bed levelling screws
		for (i = [0:2])
			rotate([0, 0, i * 120])
				translate([0, -r_effector, -1]) {
					cylinder(r = d_M3_screw / 2, h = t_effector + 2);

					translate([0, 0, - 1])
						cylinder(r = d_M3_nut / 2, h = h_M3_nut + 1, $fn = 6);
				}

		translate([0, 0, -1])
			bed_lock(t_effector + 2);
	}

}

module bed_lock(t) {
	union() {
		hull() {
			for (i = [0:2])
				rotate([0, 0, i * 120 + 60])
					translate([0, r_effector_sides / 3, 0])
						cylinder(r = l_add_effector / 2, h = t);
		}
	}
}

module bed_adapter() {
	difference() {
		union() {
			bed_lock(t_effector);

			for (i = [0:2])
				rotate([0, 0, i * 120])
					translate([0, 10, t_effector + 4])
						rotate([0, 0, 90])
							spring_mount();
		}

		for (i = [0:2])
			rotate([0, 0, i * 120 + 60])
				translate([0, r_effector_sides / 3 + 5, -1])
					cylinder(r = d_M3_screw / 2, h = t_effector + 2);
	}
}


// a complete tower with rods of length l_guide_rods
module tower() {
	// guide rods
	for (i = [-1, 1])
		translate([i * cc_guides / 2, 0, 0])
			color([0.7, 0.7, 0.7])
				cylinder(r = d_guides / 2, h = l_guide_rods, center = true);

	// idler end
	translate([0, 0, (l_guide_rods - t_clamp) / 2])
		end_idler();

	// motor end
	translate([0, 0, -(l_guide_rods - t_clamp) / 2])
		end_motor();
}

module assembly() {
	for (i = [0:2])
		// towers
		rotate([0, 0, i * 120]) {
			translate([0, r_tower_center, 0])
				tower();

		// connecting boards
		for(j = [-1, 1])
			translate([cc_mount / 2, r_tower_center, j * (l_guide_rods - t_clamp) / 2])
				rotate([0, 0, 30])
					translate([w_mount - 3, -l_brd / 2 - l_pad_mount, 0])
						color([139/255, 69/255, 19/255])
							cube([w_mount, l_brd, t_clamp], center = true);
		}
}


