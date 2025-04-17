import time

# ANSI color codes (works in most Unix/Linux/macOS terminals)
class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"
    
    # Foreground colors
    BLACK = "\033[30m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    WHITE = "\033[37m"
    
    # Background colors
    BG_BLACK = "\033[40m"
    BG_RED = "\033[41m"
    BG_GREEN = "\033[42m"
    BG_YELLOW = "\033[43m"
    BG_BLUE = "\033[44m"
    BG_MAGENTA = "\033[45m"
    BG_CYAN = "\033[46m"
    BG_WHITE = "\033[47m"

def log_success(message):
    """Log a success message in green with a checkmark symbol"""
    print(f"{Colors.GREEN}✓ {message}{Colors.RESET}")

def log_info(message):
    """Log an information message in cyan with an info symbol"""
    print(f"{Colors.CYAN}ℹ {message}{Colors.RESET}")

def log_warning(message):
    """Log a warning message in yellow with a warning symbol"""
    print(f"{Colors.YELLOW}⚠ {message}{Colors.RESET}")

def log_error(message):
    """Log an error message in red with an error symbol"""
    print(f"{Colors.RED}✗ {message}{Colors.RESET}")

def log_highlight(message):
    """Log a highlighted message in magenta with an arrow symbol"""
    print(f"{Colors.MAGENTA}➤ {message}{Colors.RESET}")

def log_progress(current, total, prefix="Progress", suffix="Complete", length=50):
    """Display a progress bar with the given parameters
    
    Args:
        current: Current progress value
        total: Total value for 100% progress
        prefix: Text to display before the progress bar
        suffix: Text to display after the progress bar
        length: Length of the progress bar in characters
    """
    percent = float(current) / float(total)
    filled_length = int(length * percent)
    bar = Colors.GREEN + "█" * filled_length + Colors.WHITE + "░" * (length - filled_length) + Colors.RESET
    print(f"\r{prefix} |{bar}| {current}/{total} {suffix} ({percent:.1%})", end="\r")
    if current == total:
        print()

def print_summary_box(title, data_dict, elapsed_time=None):
    """Print a formatted summary box with the given title and data
    
    Args:
        title: Title to display at the top of the box
        data_dict: Dictionary of labels and values to display in the box
        elapsed_time: Optional elapsed time to display at the bottom
    """
    width = 60
    print(f"\n{Colors.BG_BLUE}{Colors.WHITE}{'=' * width}{Colors.RESET}")
    print(f"{Colors.BG_BLUE}{Colors.WHITE}{title:^{width}}{Colors.RESET}")
    print(f"{Colors.BG_BLUE}{Colors.WHITE}{'=' * width}{Colors.RESET}")
    
    for label, value in data_dict.items():
        print(f"{Colors.BG_BLUE}{Colors.WHITE}{label + ':':<20}{value:>40}{Colors.RESET}")
    
    if elapsed_time is not None:
        formatted_time = f"{elapsed_time:.2f}"
        print(f"{Colors.BG_BLUE}{Colors.WHITE}{'Time (seconds):':<20}{formatted_time:>40}{Colors.RESET}")
    
    print(f"{Colors.BG_BLUE}{Colors.WHITE}{'=' * width}{Colors.RESET}")

class Timer:
    """Simple timer class to measure elapsed time"""
    
    def __init__(self):
        """Initialize the timer"""
        self.start_time = time.time()
    
    def reset(self):
        """Reset the timer"""
        self.start_time = time.time()
    
    def elapsed(self):
        """Get the elapsed time in seconds"""
        return time.time() - self.start_time