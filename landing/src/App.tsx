import { MotionConfig } from "framer-motion";
import { Hero } from "./sections/Hero";
import { About } from "./sections/About";
import { Features } from "./sections/Features";
import { Instalar } from "./sections/Instalar";
import { Footer } from "./sections/Footer";

export default function App() {
  return (
    <MotionConfig reducedMotion="user">
      <Hero />
      <About />
      <Features />
      <Instalar />
      <Footer />
    </MotionConfig>
  );
}
