import matplotlib.pyplot as plt
import numpy as np
import sys

LINEWIDTH = 2
TITLE = "The Great Graph"

try:
    if sys.argv[1] == 'log':
        log = True
    else:
        log = False
except:
    log = False

# Define constants
f_clk = 100e6
passwd_len = 39
hash_cycles = 71

# Define busses
busses = {"USB 2.0": 480e6/8, "USB 3.0": 5e9/8}
core_counts = [5, 10]

# Define a function to calculate s_p and mem based on n and f_target
def calculate_values(n, c, d_bus):
    s_p = 8 * passwd_len * n * c * (f_clk/71) / d_bus
    mem = s_p * 8 * (16+32+40)
    return s_p, mem

# Create the figure and subplots
fig, (ax1_n, ax1_f) = plt.subplots(2, 1, linewidth=LINEWIDTH)

# Create a twin axes that shares the same x-axis
ax2_n = ax1_n.twinx()
plt.title(TITLE)
plt.grid()

# Create a twin axes for the top axis
ax2_f = ax1_f.twinx()
plt.grid()

# Define the range of n values
n_values = np.arange(1, 81)

# Loop through different categorical variables (e.g., colors)
for bus_name, bus_speed in busses.items():
    for i, c in enumerate(core_counts):
        # Calculate s_p and mem for each n value
        s_p_values, mem_values = zip(*[calculate_values(n, c, bus_speed) for n in n_values])

        if log:
            # Plot s_p on the left axis
            ax1_n.loglog(n_values, s_p_values, label=f'{bus_name}, {c} cores - $s_p$', linewidth=LINEWIDTH)
            
            # Plot mem on the right axis
            ax2_n.loglog(n_values, mem_values, label=f'{bus_name}, {c} cores - mem', linestyle='--', linewidth=LINEWIDTH)

            if i == 1:
                f_target_values = n_values * c * (f_clk/71)
                # Plot s_p on the left axis
                ax1_f.loglog(f_target_values, s_p_values, label=f'{bus_name} - $s_p$', linewidth=LINEWIDTH)
                
                # Plot mem on the right axis
                ax2_f.loglog(f_target_values, mem_values, label=f'{bus_name} - mem', linestyle='--', linewidth=LINEWIDTH)
        else:
            # Plot s_p on the left axis
            ax1_n.plot(n_values, s_p_values, label=f'{bus_name}, {c} cores - $s_p$', linewidth=LINEWIDTH)
            
            # Plot mem on the right axis
            ax2_n.plot(n_values, mem_values, label=f'{bus_name}, {c} cores - mem', linestyle='--', linewidth=LINEWIDTH)

            if i == 1:
                f_target_values = n_values * c * (f_clk/71)
                # Plot s_p on the left axis
                ax1_f.plot(f_target_values, s_p_values, label=f'{bus_name} - $s_p$', linewidth=LINEWIDTH)
                
                # Plot mem on the right axis
                ax2_f.plot(f_target_values, mem_values, label=f'{bus_name} - mem', linestyle='--', linewidth=LINEWIDTH)

# Set labels for the axes
ax1_n.set_xlabel('number of nodes, $n$')
ax1_n.set_ylabel('salts required for maximum utilization\n$s_p$')
ax2_n.set_ylabel('memory required for hashes struct array\n[Bytes]')
ax1_f.set_xlabel('Hashing frequency\n$f_{hashing}$ [H/s]')
ax1_f.set_ylabel('salts required for maximum utilization\n$s_p$')
ax2_f.set_ylabel('memory required for hashes struct array\n[Bytes]')

# Add legends
lines, labels = ax1_n.get_legend_handles_labels()
lines2, labels2 = ax2_n.get_legend_handles_labels()
lines_f, labels_f = ax1_f.get_legend_handles_labels()
lines2_f, labels2_f = ax2_f.get_legend_handles_labels()
lines.extend(lines2)
labels.extend(labels2)
ax1_n.legend(lines, labels, loc='upper left')
lines_f.extend(lines2_f)
labels_f.extend(labels2_f)
ax1_f.legend(lines_f, labels_f, loc='upper left')

# Show the plot
plt.show()
