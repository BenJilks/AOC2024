namespace Day14
{
    using Vec2 = (int x, int y);

    class Util
    {
        public static int WrappingMod(int x, int m)
        {
            return (x % m + m) % m;
        }
    }

    class Robot
    {
        public Vec2 position { get; private set; }
        private Vec2 velocity;

        public Robot(Vec2 position, Vec2 velocity)
        {
            this.position = position;
            this.velocity = velocity;
        }

        public void Step(int width, int height)
        {
            position = (
                x: Util.WrappingMod(position.x + velocity.x, width),
                y: Util.WrappingMod(position.y + velocity.y, height)
            );
        }
    }

    class Grid
    {
        private List<Robot> robots = new List<Robot>();
        private int[] robotCountMap;
        private int width;
        private int height;

        public Grid(string filePath, int width, int height)
        {
            robotCountMap = new int[width * height];
            this.width = width;
            this.height = height;

            foreach (var line in File.ReadLines(filePath))
            {
                var position = (x: 0, y: 0);
                var velocity = (x: 0, y: 0);
                foreach (var assignment in line.Split(' '))
                {
                    var parts = assignment.Split('=');
                    var coordinate = parts[1].Split(",");

                    Vec2 vector = (x: int.Parse(coordinate[0]), y: int.Parse(coordinate[1]));
                    switch (parts[0])
                    {
                        case "p": position = vector; break;
                        case "v": velocity = vector; break;
                    }
                }

                robots.Add(new Robot(position, velocity));
                robotCountMap[position.y * width + position.x] += 1;
            }
        }

        public void Step()
        {
            Array.Fill(robotCountMap, 0);
            foreach (var robot in robots)
            {
                robot.Step(width, height);
                robotCountMap[robot.position.y * width + robot.position.x] += 1;
            }
        }

        public int ComputeSaftyScore()
        {
            var quadrents = new int[4];
            var midX = width / 2;
            var midY = height / 2;
            foreach (var robot in robots)
            {
                if (robot.position.y == midY || robot.position.x == midX)
                    continue;

                var quadrentX = robot.position.x < midX ? 0 : 1;
                var quadrentY = robot.position.y < midY ? 0 : 1;
                quadrents[quadrentY * 2 + quadrentX] += 1;
            }

            return quadrents.Aggregate(1, (acc, x) => acc * x);
        }

        public int MaxRobotLine()
        {
            int maxLine = 0;

            for (int x = 0; x < width; ++x)
            {
                int? lineStart = null;
                for (int y = 0; y < height; ++y)
                {
                    if (robotCountMap[y * width + x] == 1)
                    {
                        if (lineStart == null)
                            lineStart = y;
                        maxLine = Math.Max(y - lineStart.Value + 1, maxLine);
                    }
                    else
                    {
                        lineStart = null;
                    }
                }
            }

            return maxLine;
        }

        static int Task1()
        {
            var grid = new Grid("input.txt", 101, 103);
            for (int i = 0; i < 100; ++i)
                grid.Step();

            return grid.ComputeSaftyScore();
        }

        static int Task2()
        {
            var grid = new Grid("input.txt", 101, 103);

            int stepCount = 0;
            while (grid.MaxRobotLine() < 10)
            {
                grid.Step();
                stepCount += 1;
            }

            return stepCount;
        }

        static void Main(string[] args)
        {
            Console.WriteLine("task1 = " + Task1());
            Console.WriteLine("task2 = " + Task2());
        }
    }
}
