/*
 *	wiic
 *
 *	This file is part of WiiC, written by:
 *		Gabriele Randelli
 *		Email: randelli@dis.uniroma1.it
 *
 *	Copyright 2010
 *
 *	This file is based on Wiiuse, written By:
 *		Michael Laforest	< para >
 *		Email: < thepara (--AT--) g m a i l [--DOT--] com >
 *
 *	Copyright 2006-2007
 *
 *	This file is part of wiic.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *	$Header$
 *
 */

/**
 *	@file
 *
 *	@brief Example using the wiic API.
 *
 *	This file is an example of how to use the wiic library.
 */

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <wiic.h>


#define MAX_WIIMOTES				4

int exiting = 0;

#define printf(...)

char *WiiAddr;
int MaxSamples = 1, Samples = 0;
double Weight = 0.0;
int TapMax = 1, TapCount = 0, IdleMax = 1, IdleCount = 0;

/**
 *	@brief Callback that handles an event.
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *
 *	This function is called automatically by the wiic library when an
 *	event occurs on the specified wiimote.
 */
void handle_event(struct wiimote_t* wm) {
//	printf("\n\n--- EVENT [id %i] ---\n", wm->unid);

	if (IS_PRESSED(wm, WIIMOTE_BUTTON_A)) {
		++TapCount, IdleCount = 0;
	}

	else if (++IdleCount >= IdleMax) {

		if (TapCount > TapMax)
			fprintf(stdout, "PUSH=%d\n", TapCount);
		else if (TapCount > 0)
			fprintf(stdout, "TAP=%d\n", TapCount);

		TapCount = 0;

		IdleCount = 0;
	}

	/* if a button is pressed, report it */
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_A))		printf("A pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_B))		printf("B pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_UP))		printf("UP pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_DOWN))	printf("DOWN pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_LEFT))	printf("LEFT pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_RIGHT))	printf("RIGHT pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_MINUS))	printf("MINUS pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_PLUS))	printf("PLUS pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_ONE))		printf("ONE pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_TWO))		printf("TWO pressed\n");
	if (IS_PRESSED(wm, WIIMOTE_BUTTON_HOME))	printf("HOME pressed\n");

	/*
	 *	Pressing minus will tell the wiimote we are no longer interested in movement.
	 *	This is useful because it saves battery power.
	 */
	if (IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_MINUS))
		wiic_motion_sensing(wm, 0);

	/*
	 *	Pressing plus will tell the wiimote we are interested in movement.
	 */
	if (IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_PLUS))
		wiic_motion_sensing(wm, 1);
		
	if(IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_LEFT))
		wiic_set_motion_plus(wm,0);
	if(IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_RIGHT))
		wiic_set_motion_plus(wm,1);
	/*
	 *	Pressing B will toggle the rumble
	 *
	 *	if B is pressed but is not held, toggle the rumble
	 */
	if (IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_B))
		wiic_toggle_rumble(wm);

	if (IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_UP))
		wiic_set_ir(wm, 1);
	if (IS_JUST_PRESSED(wm, WIIMOTE_BUTTON_DOWN))
		wiic_set_ir(wm, 0);

	/* if the accelerometer is turned on then print angles */
	if (WIIC_USING_ACC(wm)) {
		printf("wiimote roll  = %f\n", wm->orient.angle.roll);
		printf("wiimote pitch = %f\n", wm->orient.angle.pitch);
		printf("wiimote yaw   = %f\n", wm->orient.angle.yaw);
	}

	/* if the Motion Plus is turned on then print angle rates */
	if (WIIC_USING_MOTION_PLUS(wm)) {
		printf("motion plus roll rate = %f [%f]\n", wm->exp.mp.gyro_rate.roll, wm->exp.mp.a_gyro_rate.roll);
		printf("motion plus pitch rate = %f [%f]\n", wm->exp.mp.gyro_rate.pitch, wm->exp.mp.a_gyro_rate.pitch);
		printf("motion plus yaw rate = %f [%f]\n", wm->exp.mp.gyro_rate.yaw, wm->exp.mp.a_gyro_rate.yaw);
	}

	/*
	 *	If IR tracking is enabled then print the coordinates
	 *	on the virtual screen that the wiimote is pointing to.
	 *
	 *	Also make sure that we see at least 1 dot.
	 */
	if (WIIC_USING_IR(wm)) {
		int i = 0;

		/* go through each of the 4 possible IR sources */
		for (; i < 4; ++i) {
			/* check if the source is visible */
			if (wm->ir.dot[i].visible)
				printf("IR source %i: (%u, %u)\n", i, wm->ir.dot[i].x, wm->ir.dot[i].y);
		}

		printf("IR cursor: (%u, %u)\n", wm->ir.x, wm->ir.y);
		printf("IR z distance: %f\n", wm->ir.z);
	}

	/* show events specific to supported expansions */
	if (wm->exp.type == EXP_NUNCHUK) {
		/* nunchuk */
		struct nunchuk_t* nc = (nunchuk_t*)&wm->exp.nunchuk;

		if (IS_PRESSED(nc, NUNCHUK_BUTTON_C))		printf("Nunchuk: C pressed\n");
		if (IS_PRESSED(nc, NUNCHUK_BUTTON_Z))		printf("Nunchuk: Z pressed\n");

		printf("nunchuk roll  = %f\n", nc->orient.angle.roll);
		printf("nunchuk pitch = %f\n", nc->orient.angle.pitch);
		printf("nunchuk yaw   = %f\n", nc->orient.angle.yaw);

		printf("nunchuk joystick angle:     %f\n", nc->js.ang);
		printf("nunchuk joystick magnitude: %f\n", nc->js.mag);
	} else if (wm->exp.type == EXP_CLASSIC) {
		/* classic controller */
		struct classic_ctrl_t* cc = (classic_ctrl_t*)&wm->exp.classic;

		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_ZL))			printf("Classic: ZL pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_B))			printf("Classic: B pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_Y))			printf("Classic: Y pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_A))			printf("Classic: A pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_X))			printf("Classic: X pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_ZR))			printf("Classic: ZR pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_LEFT))		printf("Classic: LEFT pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_UP))			printf("Classic: UP pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_RIGHT))		printf("Classic: RIGHT pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_DOWN))		printf("Classic: DOWN pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_FULL_L))		printf("Classic: FULL L pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_MINUS))		printf("Classic: MINUS pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_HOME))		printf("Classic: HOME pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_PLUS))		printf("Classic: PLUS pressed\n");
		if (IS_PRESSED(cc, CLASSIC_CTRL_BUTTON_FULL_R))		printf("Classic: FULL R pressed\n");

		printf("classic L button pressed:         %f\n", cc->l_shoulder);
		printf("classic R button pressed:         %f\n", cc->r_shoulder);
		printf("classic left joystick angle:      %f\n", cc->ljs.ang);
		printf("classic left joystick magnitude:  %f\n", cc->ljs.mag);
		printf("classic right joystick angle:     %f\n", cc->rjs.ang);
		printf("classic right joystick magnitude: %f\n", cc->rjs.mag);
	} else if (wm->exp.type == EXP_GUITAR_HERO_3) {
		/* guitar hero 3 guitar */
		struct guitar_hero_3_t* gh3 = (guitar_hero_3_t*)&wm->exp.gh3;

		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_STRUM_UP))		printf("Guitar: Strum Up pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_STRUM_DOWN))	printf("Guitar: Strum Down pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_YELLOW))		printf("Guitar: Yellow pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_GREEN))		printf("Guitar: Green pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_BLUE))			printf("Guitar: Blue pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_RED))			printf("Guitar: Red pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_ORANGE))		printf("Guitar: Orange pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_PLUS))			printf("Guitar: Plus pressed\n");
		if (IS_PRESSED(gh3, GUITAR_HERO_3_BUTTON_MINUS))		printf("Guitar: Minus pressed\n");

		printf("Guitar whammy bar:          %f\n", gh3->whammy_bar);
		printf("Guitar joystick angle:      %f\n", gh3->js.ang);
		printf("Guitar joystick magnitude:  %f\n", gh3->js.mag);
	} else if(wm->exp.type == EXP_BALANCE_BOARD) {
		struct balance_board_t* bb = (balance_board_t*)&wm->exp.bb;

Weight += bb->pressure_weight.weight;
if (++Samples >= MaxSamples) {
	fprintf(stdout, "WEIGHT=%f\n", Weight / Samples);
	Weight = 0.0, Samples = 0;
}

/*
		printf("balance board top left weight: %f\n", bb->pressure_weight.top_left);
		printf("balance board top right weight: %f\n", bb->pressure_weight.top_right);
		printf("balance board bottom left weight: %f\n", bb->pressure_weight.bottom_left);
		printf("balance board bottom right weight: %f\n", bb->pressure_weight.bottom_right);
		printf("balance board total weight: %f\n", bb->pressure_weight.weight);
*/
	}
}


/**
 *	@brief Callback that handles a read event.
 *
 *	@param wm		Pointer to a wiimote_t structure.
 *	@param data		Pointer to the filled data block.
 *	@param len		Length in bytes of the data block.
 *
 *	This function is called automatically by the wiic library when
 *	the wiimote has returned the full data requested by a previous
 *	call to wiic_read_data().
 *
 *	You can read data on the wiimote, such as Mii data, if
 *	you know the offset address and the length.
 *
 *	The \a data pointer was specified on the call to wiic_read_data().
 *	At the time of this function being called, it is not safe to deallocate
 *	this buffer.
 */
void handle_read(struct wiimote_t* wm, byte* data, unsigned short len) {
	int i = 0;

	printf("\n\n--- DATA READ [wiimote id %i] ---\n", wm->unid);
	printf("finished read of size %i\n", len);
	for (; i < len; ++i) {
		if (!(i%16))
			printf("\n");
		printf("%x ", data[i]);
	}
	printf("\n\n");
}


/**
 *	@brief Callback that handles a controller status event.
 *
 *	@param wm				Pointer to a wiimote_t structure.
 *	@param attachment		Is there an attachment? (1 for yes, 0 for no)
 *	@param speaker			Is the speaker enabled? (1 for yes, 0 for no)
 *	@param ir				Is the IR support enabled? (1 for yes, 0 for no)
 *	@param led				What LEDs are lit.
 *	@param battery_level	Battery level, between 0.0 (0%) and 1.0 (100%).
 *
 *	This occurs when either the controller status changed
 *	or the controller status was requested explicitly by
 *	wiic_status().
 *
 *	One reason the status can change is if the nunchuk was
 *	inserted or removed from the expansion port.
 */
void handle_ctrl_status(struct wiimote_t* wm) {
	printf("\n\n--- CONTROLLER STATUS [wiimote id %i] ---\n", wm->unid);

	printf("attachment:      %i\n", wm->exp.type);
	printf("speaker:         %i\n", WIIC_USING_SPEAKER(wm));
	printf("ir:              %i\n", WIIC_USING_IR(wm));
	printf("leds:            %i %i %i %i\n", WIIC_IS_LED_SET(wm, 1), WIIC_IS_LED_SET(wm, 2), WIIC_IS_LED_SET(wm, 3), WIIC_IS_LED_SET(wm, 4));
	printf("battery:         %f %%\n", wm->battery_level);
}


/**
 *	@brief Callback that handles a disconnection event.
 *
 *	@param wm				Pointer to a wiimote_t structure.
 *
 *	This can happen if the POWER button is pressed, or
 *	if the connection is interrupted.
 */
void handle_disconnect(wiimote* wm) {
	printf("\n\n--- DISCONNECTED [wiimote id %i] ---\n", wm->unid);
	exiting = 1;
}


void test(struct wiimote_t* wm, byte* data, unsigned short len) {
	printf("test: %i [%x %x %x %x]\n", len, data[0], data[1], data[2], data[3]);
}



/**
 *	@brief main()
 *
 *	Connect to up to two wiimotes and print any events
 *	that occur on either device.
 */
int main(int argc, char** argv) {
	wiimote** wiimotes;
	int found, connected;

int c;

while ((c = getopt (argc, argv, "w:s:t:i:")) != -1) switch (c) {
	case 'w':
		WiiAddr = optarg;
		break;
	case 's':
		MaxSamples = atoi(optarg);
		break;
	case 't':
		TapMax = atoi(optarg);
		break;
	case 'i':
		IdleMax = atoi(optarg);
		break;
	case '?':
	default:
		fprintf(stderr, "Usage: %s [-w addr] [-s sample_size] [-t tap_max] [-i idle_max]\n", argv[0]);
		break;
}

	/*
	 *	Initialize an array of wiimote objects.
	 *
	 *	The parameter is the number of wiimotes I want to create.
	 */
	wiimotes =  wiic_init(MAX_WIIMOTES);

(void)setbuf(stdout, NULL);

if (!WiiAddr) {
	/*
	 *	Find wiimote devices
	 *
	 *	Now we need to find some wiimotes.
	 *	Give the function the wiimote array we created, and tell it there
	 *	are MAX_WIIMOTES wiimotes we are interested in.
	 *
	 *	Set the timeout to be 5 seconds.
	 *
	 *	This will return the number of actual wiimotes that are in discovery mode.
	 */
	found = wiic_find(wiimotes, MAX_WIIMOTES, 5);
	if (!found) {
		printf ("No wiimotes found.");
		return 0;
	}

	/*
	 *	Connect to the wiimotes
	 *
	 *	Now that we found some wiimotes, connect to them.
	 *	Give the function the wiimote array and the number
	 *	of wiimote devices we found.
	 *
	 *	This will return the number of established connections to the found wiimotes.
	 */
	connected = wiic_connect(wiimotes, found, 0);
}

else {
	found = 1;
	connected = wiic_connect_single(wiimotes[0], WiiAddr, 0);
}

	if (connected)
		printf("Connected to %i wiimotes (of %i found).\n", connected, found);
	else {
		printf("Failed to connect to any wiimote.\n");
		return 0;
	}

	/*
	 *	Now set the LEDs and rumble for a second so it's easy
	 *	to tell which wiimotes are connected (just like the wii does).
	 */
	wiic_set_leds(wiimotes[0], WIIMOTE_LED_1);
	wiic_rumble(wiimotes[0], 1);
	usleep(200000);
	wiic_rumble(wiimotes[0], 0);

	/*
	 *	Maybe I'm interested in the battery power of the 0th
	 *	wiimote.  This should be WIIMOTE_ID_1 but to be sure
	 *	you can get the wiimote assoicated with WIIMOTE_ID_1
	 *	using the wiic_get_by_id() function.
	 *
	 *	A status request will return other things too, like
	 *	if any expansions are plugged into the wiimote or
	 *	what LEDs are lit.
	 */
	wiic_status(wiimotes[0]);
	
	printf("\nPress PLUS (MINUS) to enable (disable) Motion Sensing Report (only accelerometers)\n");
	printf("Press RIGHT (LEFT) to enable (disable) Motion Plus (requires Motion Sensing enabled)\n");
	printf("Press UP (DOWN) to enable (disable) IR camera (requires some IR led)\n");

	/*
	 *	This is the main loop
	 *
	 *	wiic_poll() needs to be called with the wiimote array
	 *	and the number of wiimote structures in that array
	 *	(it doesn't matter if some of those wiimotes are not used
	 *	or are not connected).
	 *
	 *	This function will set the event flag for each wiimote
	 *	when the wiimote has things to report.
	 */
	while (!exiting) {
		if (wiic_poll(wiimotes, connected)) {
			/*
			 *	This happens if something happened on any wiimote.
			 *	So go through each one and check if anything happened.
			 */
			int i = 0;
			for (; i < MAX_WIIMOTES; ++i) {
				switch (wiimotes[i]->event) {
					case WIIC_EVENT:
						// a generic event occured
						handle_event(wiimotes[i]);
						break;

					case WIIC_STATUS:
						// a status event occured
						handle_ctrl_status(wiimotes[i]);
						break;

					case WIIC_DISCONNECT:
					case WIIC_UNEXPECTED_DISCONNECT:
						// the wiimote disconnected
						handle_disconnect(wiimotes[i]);
						break;

					case WIIC_READ_DATA:
						/*
						 *	Data we requested to read was returned.
						 *	Take a look at wiimotes[i]->read_req
						 *	for the data.
						 */
						break;

					case WIIC_NUNCHUK_INSERTED:
						/*
						 *	a nunchuk was inserted
						 *	This is a good place to set any nunchuk specific
						 *	threshold values.  By default they are the same
						 *	as the wiimote.
						 */
						printf("Nunchuk inserted.\n");
						break;

					case WIIC_CLASSIC_CTRL_INSERTED:
						printf("Classic controller inserted.\n");
						break;

					case WIIC_GUITAR_HERO_3_CTRL_INSERTED:
						// some expansion was inserted 
						handle_ctrl_status(wiimotes[i]);
						break;
						
					case WIIC_MOTION_PLUS_INSERTED:
						printf("Motion Plus inserted.\n");
						break;
						
					case WIIC_BALANCE_BOARD_INSERTED:
						printf("Balance Board connected.\n");
						break;
						
					case WIIC_BALANCE_BOARD_REMOVED:
						printf("Balance Board disconnected.\n");
						break;
						
					case WIIC_NUNCHUK_REMOVED:
					case WIIC_CLASSIC_CTRL_REMOVED:
					case WIIC_GUITAR_HERO_3_CTRL_REMOVED:
					case WIIC_MOTION_PLUS_REMOVED:
						// some expansion was removed 
						handle_ctrl_status(wiimotes[i]);
						printf("An expansion was removed.\n");
						break;
						
					default:
						break;
				}
			}
		}
	}

	/*
	 *	Disconnect the wiimotes
	 */
	wiic_cleanup(wiimotes, MAX_WIIMOTES);

	return 0;
}
