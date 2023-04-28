import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.distribution.NormalDistribution;
import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;

import java.io.*;

import java.io.File;
import java.io.FileInputStream;
import java.util.Scanner;

public class test {
    public static void main(String[] args) throws Exception {
        FileInputStream is = new FileInputStream(args[0]);
        Scanner scanner = new Scanner(is);
        int q1 = 0, q2 = 0;
        q1 = scanner.nextInt();
        q2 = scanner.nextInt();
        
        NormalDistribution normalDistribution = new NormalDistribution(q1, q2);
        Complex first = new Complex(q1, q2);
        
        q1 = scanner.nextInt();
        q2 = scanner.nextInt();

        Complex second = new Complex(q2, q1);

        Complex power = first.pow(second);
        double randomValue = normalDistribution.sample();
    }

}
