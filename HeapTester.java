import java.awt.*;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;
import java.util.ArrayList;
import java.util.List;
import javax.swing.*;

/**
 * HeapTester - A simple GUI application to test Java heap memory usage
 * This application allows you to allocate and release memory to test
 * the Java Heap Monitor's functionality.
 */
public class HeapTester extends JFrame {
    private static final long serialVersionUID = 1L;
    
    // List to hold allocated memory blocks
    private List<byte[]> memoryBlocks = new ArrayList<>();
    
    // Memory block size (10MB)
    private static final int BLOCK_SIZE = 10 * 1024 * 1024;
    
    // UI Components
    private JLabel heapUsedLabel;
    private JLabel heapMaxLabel;
    private JLabel heapPercentLabel;
    private JProgressBar heapUsageBar;
    private JButton allocateButton;
    private JButton releaseButton;
    private JButton releaseAllButton;
    private JSlider allocationSlider;
    private JLabel sliderValueLabel;
    private Timer updateTimer;
    
    public HeapTester() {
        setTitle("Java Heap Tester");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(500, 400);
        setLocationRelativeTo(null);
        
        // Create UI components
        createUI();
        
        // Start timer to update heap usage display
        updateTimer = new Timer(1000, e -> updateHeapUsageDisplay());
        updateTimer.start();
        
        // Initial update
        updateHeapUsageDisplay();
    }
    
    private void createUI() {
        // Main panel with BorderLayout
        JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
        mainPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        
        // Status panel (North)
        JPanel statusPanel = new JPanel(new GridLayout(4, 1, 5, 5));
        statusPanel.setBorder(BorderFactory.createTitledBorder("Heap Status"));
        
        heapUsedLabel = new JLabel("Used: 0 MB");
        heapMaxLabel = new JLabel("Max: 0 MB");
        heapPercentLabel = new JLabel("Usage: 0%");
        heapUsageBar = new JProgressBar(0, 100);
        heapUsageBar.setStringPainted(true);
        
        statusPanel.add(heapUsedLabel);
        statusPanel.add(heapMaxLabel);
        statusPanel.add(heapPercentLabel);
        statusPanel.add(heapUsageBar);
        
        // Control panel (Center)
        JPanel controlPanel = new JPanel(new BorderLayout(10, 10));
        controlPanel.setBorder(BorderFactory.createTitledBorder("Memory Control"));
        
        // Slider panel
        JPanel sliderPanel = new JPanel(new BorderLayout(5, 5));
        allocationSlider = new JSlider(1, 10, 1);
        allocationSlider.setMajorTickSpacing(1);
        allocationSlider.setPaintTicks(true);
        allocationSlider.setPaintLabels(true);
        allocationSlider.setSnapToTicks(true);
        
        sliderValueLabel = new JLabel("Block size: 10 MB", JLabel.CENTER);
        
        allocationSlider.addChangeListener(e -> {
            int value = allocationSlider.getValue();
            sliderValueLabel.setText("Block size: " + (value * 10) + " MB");
        });
        
        sliderPanel.add(new JLabel("Allocation Size:"), BorderLayout.NORTH);
        sliderPanel.add(allocationSlider, BorderLayout.CENTER);
        sliderPanel.add(sliderValueLabel, BorderLayout.SOUTH);
        
        // Button panel
        JPanel buttonPanel = new JPanel(new GridLayout(1, 3, 10, 10));
        
        allocateButton = new JButton("Allocate Memory");
        releaseButton = new JButton("Release Memory");
        releaseAllButton = new JButton("Release All");
        
        allocateButton.addActionListener(e -> allocateMemory());
        releaseButton.addActionListener(e -> releaseMemory());
        releaseAllButton.addActionListener(e -> releaseAllMemory());
        
        buttonPanel.add(allocateButton);
        buttonPanel.add(releaseButton);
        buttonPanel.add(releaseAllButton);
        
        controlPanel.add(sliderPanel, BorderLayout.CENTER);
        controlPanel.add(buttonPanel, BorderLayout.SOUTH);
        
        // Info panel (South)
        JPanel infoPanel = new JPanel(new BorderLayout());
        infoPanel.setBorder(BorderFactory.createTitledBorder("Information"));
        
        JTextArea infoText = new JTextArea(
            "This application allows you to test the Java Heap Monitor by allocating\n" +
            "and releasing memory. Use the slider to set the allocation size and the\n" +
            "buttons to control memory usage. The status panel shows current heap usage."
        );
        infoText.setEditable(false);
        infoText.setBackground(new Color(240, 240, 240));
        infoPanel.add(infoText, BorderLayout.CENTER);
        
        // Add panels to main panel
        mainPanel.add(statusPanel, BorderLayout.NORTH);
        mainPanel.add(controlPanel, BorderLayout.CENTER);
        mainPanel.add(infoPanel, BorderLayout.SOUTH);
        
        // Set main panel as content pane
        setContentPane(mainPanel);
    }
    
    private void allocateMemory() {
        try {
            int blockCount = allocationSlider.getValue();
            for (int i = 0; i < blockCount; i++) {
                memoryBlocks.add(new byte[BLOCK_SIZE]);
            }
            updateHeapUsageDisplay();
        } catch (OutOfMemoryError e) {
            JOptionPane.showMessageDialog(this, 
                "Out of memory! Try releasing some memory first.",
                "Memory Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void releaseMemory() {
        int blockCount = Math.min(allocationSlider.getValue(), memoryBlocks.size());
        for (int i = 0; i < blockCount; i++) {
            if (!memoryBlocks.isEmpty()) {
                memoryBlocks.remove(memoryBlocks.size() - 1);
            }
        }
        System.gc(); // Request garbage collection
        updateHeapUsageDisplay();
    }
    
    private void releaseAllMemory() {
        memoryBlocks.clear();
        System.gc(); // Request garbage collection
        updateHeapUsageDisplay();
    }
    
    private void updateHeapUsageDisplay() {
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
        MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
        
        long used = heapUsage.getUsed();
        long max = heapUsage.getMax();
        
        // Convert to MB for display
        long usedMB = used / (1024 * 1024);
        long maxMB = max / (1024 * 1024);
        
        // Calculate percentage
        int percentage = (int) ((double) used / max * 100);
        
        // Update labels
        heapUsedLabel.setText("Used: " + usedMB + " MB");
        heapMaxLabel.setText("Max: " + maxMB + " MB");
        heapPercentLabel.setText("Usage: " + percentage + "%");
        
        // Update progress bar
        heapUsageBar.setValue(percentage);
        
        // Change color based on usage
        if (percentage < 50) {
            heapUsageBar.setForeground(new Color(0, 153, 0)); // Green
        } else if (percentage < 75) {
            heapUsageBar.setForeground(new Color(255, 204, 0)); // Yellow
        } else {
            heapUsageBar.setForeground(new Color(204, 0, 0)); // Red
        }
    }
    
    public static void main(String[] args) {
        // Set look and feel to system default
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        // Launch the application
        SwingUtilities.invokeLater(() -> {
            HeapTester tester = new HeapTester();
            tester.setVisible(true);
        });
    }
}
