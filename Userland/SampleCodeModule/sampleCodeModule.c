/* sampleCodeModule.c */
#include <userio.h>
#include <usyscalls.h>
#include <colors.h>

extern void divideByZero();
extern void invalidOpcode();
extern void fillRegs();

void pong();

int strncmp(char * str1, char * str2, int length);
int commandMatch(char * str1, char * str2, int length);
void strcpy(char * dest, char * src);
void analizeBuffer(char * buffer, int count);

static char * commandsNames[] = {"help", "time", "date", "registers", "fillregs", "div0", "invalidop", "pong", "clear"};

static char *commands[] = {
	"\thelp: gives you a list of all existants commands.\n",
	"\ttime: prints the time of the OS.\n",
	"\tdate: prints the date of the OS.\n",
	"\tregisters: print the state of the registers at the time you screenshot them with CTRL key.\n",
	"\tfillregs: fill the registers with stepped values for testing.\n",
	"\tdiv0: divide by zero to trigger exception\n",
	"\tinvalidop: trigger invalid operation code exception\n",
	"\tpong: go to play the \"pong\" game.\n",
	"\tclear: clears the OS screen.\n"
};
#define COMMANDS_QUANTITY 9

char * getTime(){
	static char bufferTime[9];
	sys_get_time(bufferTime);
	return bufferTime;
}

char * getDate(){
	static char bufferDate[9];
	sys_get_date(bufferDate);
	return bufferDate;
}


int main() {
	printColor("Welcome to ben@OS: type \"help\" for command list\n", ORANGE);
	printColor("\nben@OS: $> ", GREEN);

	int count = 0;	
	char buffer[1024] = {0};
	char oldBuffer[1024] = {0};
	char flag = 0; // Used for up arrow
	while(1) {
		char c = getChar();
		if (c == '\n') {
			buffer[count] = 0;
			analizeBuffer(buffer, count);
			printColor("\nben@OS: $> ", GREEN);
			strcpy(oldBuffer, buffer);
			flag = 1;
			count = 0;
		} else if (c == '\b') {
			if (count > 0) {
				printChar(c);
				count--;
			}
		} else if (c == '\t') {
			// analize count letters of the buffer and see if match with any command, if so, complete the command
			int i = 0;
			while (i < COMMANDS_QUANTITY && !strncmp(buffer, commandsNames[i], count)) {
				i++;
			}
			if (i < COMMANDS_QUANTITY) {
				while (commandsNames[i][count] != 0) {
					printChar(commandsNames[i][count]);
					buffer[count] = commandsNames[i][count];
					count++;
				}
			}
		} else if (c == 17 && flag) {
			// up arrow
			while (count > 0) {
				printChar('\b');
				count--;
			}
			strcpy(buffer, oldBuffer);
			count = strlen(buffer);
			print(buffer);
			flag = 0;
		} else if (c == 20 && !flag) {
			// down arrow
			while (count > 0) {
				printChar('\b');
				count--;
			}
			flag = 1;
		} else if (c != 0xFF && c > 20) {
			printChar(c);
			buffer[count++] = c;
			buffer[count] = 0;
		}
	}

	return 0;
}

int strncmp(char * str1, char * str2, int length) {
	int i = 0;
	while (i < length && str1[i] != 0 && str2[i] != 0 && str1[i] == str2[i]) {
		i++;
	}
	return i == length;
}

int commandMatch(char * str1, char * command, int count) {
	int i = 0;
	if (count != strlen(command))
		return 0;
	while (str1[i] != 0 && command[i] != 0 && str1[i] == command[i] && i < count) {
		i++;
	}
	return str1[i] == command[i];
}

void strcpy(char * dest, char * src) {
	int i = 0;
	while (src[i] != 0) {
		dest[i] = src[i];
		i++;
	}
	dest[i] = 0;
}

void fillRegisters() {
	printColor("\n\nFilling registers...\n", YELLOW);
	printColor("Press CTRL to save them.\n", CYAN);
	fillRegs();
}

void analizeBuffer(char * buffer, int count) {
	if (count <= 0)
		return;
	if (commandMatch(buffer, "help", count) || commandMatch(buffer, "HELP", count)) {
		printColor("\n\nComandos disponibles:\n\n", YELLOW);
		for (int i = 0; i < COMMANDS_QUANTITY; i++) {
			printColor(commands[i], CYAN);
		}
	} else if (commandMatch(buffer, "time", count)) {
		printfColor("\n\nTime of OS: ", YELLOW);
		printfColor("%s\n", CYAN, getTime());
	} else if (commandMatch(buffer, "date", count)) {
		printfColor("\n\nDate of OS: ", YELLOW);
		printfColor("%s\n", CYAN, getDate());
	} else if (commandMatch(buffer, "registers", count)) {
		printRegs();
	} else if (commandMatch(buffer, "fillregs", count)) {
		fillRegisters();
	} else if (commandMatch(buffer, "clear", count)) {
		sys_clear_screen();
	} else if (commandMatch(buffer, "pong", count)) {
		printColor("\nir a jugar al pong\n", GREEN);
		pong();
	} else if (commandMatch(buffer, "div0", count)) {
		divideByZero();
	} else if (commandMatch(buffer, "invalidop", count)) {
		invalidOpcode();
	} else if (count > 0) {
		printColor("\nCommand not found. Type \"help\" for command list\n", RED);
	}
}