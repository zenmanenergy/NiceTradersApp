
import traceback
import re
import os
from colorama import Fore, Style

def Debugger(exception):
	error = {}
	error['ErrorMessage'] = str(exception)
	stack_trace = traceback.format_exc()
	stack_trace_lines = re.split(r'\bFile\b', stack_trace)
	desired_directory = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
	filtered_stack_trace_lines = []
	
	for line in stack_trace_lines:
		if line[1:-1].startswith("\"" + desired_directory):
			filtered_stack_trace_lines.append(line)
	
	error['StackTrace'] = filtered_stack_trace_lines
	print(Fore.RED + error['ErrorMessage'] + Style.RESET_ALL)
	print(Fore.RED + '\n'.join(error['StackTrace']) + Style.RESET_ALL)
	
	return error
